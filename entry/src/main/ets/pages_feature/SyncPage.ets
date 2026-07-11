import { Style } from '../components/Style';
import { TopBar } from '../components/Common';
import { DialogCard } from '../components/Overlays';
import { AppState, Prefs } from '../state/AppState';
import { promptAction } from '@kit.ArkUI';

interface SyncOption {
  label: string;
  selected: boolean;
}

@Component
export struct SyncPage {
  @Prop state: string;
  go: (route: string) => void = () => {};

  @StorageLink('qp_prefs') prefsSig: string = '';

  private app(): AppState { return AppState.getInstance(); }
  private prefs(): Prefs { return this.app().prefs; }

  private options(): SyncOption[] {
    const p = this.prefs();
    return [
      { label: 'Disabled', selected: p.syncProvider === 'Disabled' },
      { label: 'Nextcloud', selected: p.syncProvider === 'Nextcloud' },
      { label: 'File Storage', selected: p.syncProvider === 'File Storage' },
    ];
  }

  private notify(msg: string): void {
    try { promptAction.showToast({ message: msg, duration: 1500 }); } catch (e) {}
  }

  @Builder syncMain() {
    Column() {
      TopBar({ leading: $r('app.media.ic_back'), title: 'Syncing',
        onLeading: () => this.go('settings_main_top') })

      Row() {
        Image($r('app.media.ic_sync'))
          .width(Style.iconSize).height(Style.iconSize)
          .fillColor(Style.icon)
          .margin({ right: 32 })
        Column() {
          Text('Syncing service')
            .fontSize(16).fontColor(Style.textPrimary)
            .width('100%')
          Text(this.prefs().syncProvider)
            .fontSize(14).fontColor(Style.textSecondary)
            .width('100%')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height(64)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .key('sync_provider_row')
      .onClick(() => this.go('sync_provider_choice'))

      // New notes syncable toggle (Yes/No) - local observable.
      Row() {
        Column() {
          Text('New notes syncable by default')
            .fontSize(16).fontColor(Style.textPrimary).width('100%')
          Text('Currently: ' + this.prefs().newNotesSyncable)
            .fontSize(14).fontColor(Style.textSecondary).width('100%').margin({ top: 2 })
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Start)
        Text(this.prefs().newNotesSyncable === 'Yes' ? 'Yes' : 'No')
          .fontSize(14).fontColor(Style.accent).fontWeight(FontWeight.Medium)
      }
      .width('100%').height(64).padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .key('sync_new_notes_row')
      .onClick(() => {
        this.app().setPref('newNotesSyncable', this.prefs().newNotesSyncable === 'Yes' ? 'No' : 'Yes');
      })

      Row() {
        Column() {
          Text('Stored credentials')
            .fontSize(16).fontColor(Style.textPrimary).width('100%')
          Text(this.prefs().syncCredentialsConfigured ? 'Configured' : 'Not configured')
            .fontSize(14).fontColor(Style.textSecondary).width('100%').margin({ top: 2 })
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Start)
        Text('CLEAR')
          .fontSize(14).fontColor(Style.accent).fontWeight(FontWeight.Medium)
      }
      .width('100%').height(64).padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .key('sync_clear_creds_row')
      .onClick(() => {
        this.app().prefs.syncCredentialsConfigured = false;
        this.app().bumpVersion();
        this.notify('Credentials cleared');
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Style.bg)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder radioIndicator(selected: boolean) {
    Stack() {
      Row()
        .width(20)
        .height(20)
        .border({ width: 2, color: selected ? Style.accent : '#757983', radius: 10 })
        .backgroundColor('#FFFFFF')
      if (selected) {
        Circle({ width: 10, height: 10 }).fill(Style.accent)
      }
    }
    .width(28)
    .height(28)
    .margin({ right: 20 })
  }

  @Builder choiceBody() {
    Column() {
      ForEach(this.options(), (opt: SyncOption) => {
        Row() {
          this.radioIndicator(opt.selected)
          Text(opt.label)
            .fontSize(16)
            .fontColor(Style.textSecondary)
            .layoutWeight(1)
        }
        .width('100%')
        .height(56)
        .alignItems(VerticalAlign.Center)
        .onClick(() => {
          this.app().setPref('syncProvider', opt.label);
        })
      }, (opt: SyncOption) => opt.label + '_' + this.prefsSig)
    }
    .width('100%')
  }

  @Builder choiceActions() {
    Text('DONE!')
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor(Style.accent)
      .padding({ left: 8, right: 8, top: 8, bottom: 8 })
      .onClick(() => this.go('sync_main'))
  }

  build() {
    Stack() {
      this.syncMain()

      if (this.state === 'sync_provider_choice') {
        DialogCard({ title: 'Syncing service',
          body: () => { this.choiceBody() },
          actions: () => { this.choiceActions() },
          onDismiss: () => this.go('sync_main') })
      }
    }
    .width('100%')
    .height('100%')
  }
}
