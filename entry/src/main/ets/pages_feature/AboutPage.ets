import { Style } from '../components/Style';
import { TopBar } from '../components/Common';
import { DialogCard } from '../components/Overlays';
import { appVersionDisplay } from '../state/AppState';

interface SettingRow {
  header?: string;
  title?: string;
  subtitle?: string;
  icon?: Resource;
  route?: string;
  key: string;
}

interface LibraryRow {
  name: string;
  license: string;
}

// About feature area. Single state: about_main + about_libraries dialog.
@Component
export struct AboutPage {
  @Prop state: string;
  go: (route: string) => void = () => {};

  private rows(): SettingRow[] {
    return [
      { title: 'Version', subtitle: appVersionDisplay(), icon: $r('app.media.ic_about'), key: 'version' },
      { title: 'Website', subtitle: 'https://quillpad.github.io', icon: $r('app.media.ic_web'),
        key: 'website' },
      { title: 'Developer', subtitle: 'Arumugam J, Michael Soultanidis & Open Source Devs',
        icon: $r('app.media.ic_person'), key: 'developer' },
      { title: 'Contribute', subtitle: 'https://github.com/quillpad/quillpad',
        icon: $r('app.media.ic_code'), key: 'contribute' },
      { title: 'Support',
        subtitle: 'Creating and maintaining open-source projects is time-consuming and provides no profit.\nBuy the developers a coffee!',
        icon: $r('app.media.ic_heart'), key: 'support' },
      { title: 'Send Error Logs',
        subtitle: 'Send the application logs to the developer for investigation',
        icon: $r('app.media.ic_export_all'), key: 'send_logs' },
      { title: 'Libraries', icon: $r('app.media.ic_library'), route: 'about_libraries', key: 'libraries' }
    ];
  }

  private libraries(): LibraryRow[] {
    return [
      { name: 'Kotlin Standard Library', license: 'Apache 2.0' },
      { name: 'AndroidX Core', license: 'Apache 2.0' },
      { name: 'Material Components for Android', license: 'Apache 2.0' },
      { name: 'Room Persistence Library', license: 'Apache 2.0' },
      { name: 'Kotlin Coroutines', license: 'Apache 2.0' },
      { name: 'Markwon (markdown renderer)', license: 'Apache 2.0' },
      { name: 'Nextcloud SSO', license: 'MIT' },
      { name: 'Glide', license: 'BSD' },
    ];
  }

  @Builder aboutRow(row: SettingRow) {
    Row() {
      if (row.icon) {
        Image(row.icon)
          .width(24).height(24)
          .fillColor(Style.icon)
          .objectFit(ImageFit.Contain)
          .margin({ right: 28 })
      }
      Column() {
        Text(row.title)
          .fontSize(16).fontColor(Style.textPrimary)
          .width('100%')
        if (row.subtitle && row.subtitle.length > 0) {
          Text(row.subtitle)
            .fontSize(14).fontColor(Style.textSecondary)
            .width('100%').margin({ top: 4 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .constraintSize({ minHeight: 72 })
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .key('about_row_' + row.key)
    .onClick(() => {
      if (row.route && row.route.length > 0) {
        this.go(row.route);
      }
    })
  }

  @Builder librariesBody() {
    Column() {
      ForEach(this.libraries(), (lib: LibraryRow) => {
        Row() {
          Text(lib.name).fontSize(15).fontColor(Style.textPrimary).layoutWeight(1)
          Text(lib.license).fontSize(13).fontColor(Style.textSecondary)
        }
        .width('100%').height(40).alignItems(VerticalAlign.Center)
      }, (lib: LibraryRow) => lib.name)
    }
    .width('100%')
  }

  @Builder librariesAction() {
    Text('DONE!')
      .fontSize(14).fontColor(Style.accent).fontWeight(FontWeight.Medium)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .onClick(() => this.go('about_main'))
  }

  build() {
    Stack() {
      Column() {
        TopBar({ leading: $r('app.media.ic_back'), title: 'About',
          onLeading: () => this.go('settings_main_top') })
        Scroll() {
          Column() {
            ForEach(this.rows(), (row: SettingRow) => {
              this.aboutRow(row)
            }, (row: SettingRow) => row.key)
          }
          .width('100%')
          .padding({ top: 8, bottom: 40 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .align(Alignment.TopStart)
      }
      .width('100%').height('100%')

      if (this.state === 'about_libraries') {
        DialogCard({ title: 'Libraries',
          body: () => { this.librariesBody() },
          actions: () => { this.librariesAction() },
          onDismiss: () => this.go('about_main') })
      }
    }
    .width('100%').height('100%')
    .backgroundColor(Style.bg)
  }
}
