import { Style } from './Style';
import { Notebook } from '../model/Data';
import { AppState } from '../state/AppState';

// Navigation drawer overlay matching Android page_08:
// blue sync header, Quillpad brand, All Notes(selected)/Archive/Deleted,
// Notebooks section (Your Notebooks + per-notebook rows), Tags, Settings, About.
@Component
export struct NavDrawer {
  @StorageLink('qp_notes_version') notesVersion: number = 0;
  @StorageLink('qp_route') routeMirror: string = 'main_grid_default:';
  onNavigate: (route: string) => void = () => {};
  onDismiss: () => void = () => {};

  private app(): AppState { return AppState.getInstance(); }

  private liveNotebooks(): Notebook[] {
    return this.app().sortedNotebooks();
  }

  // Derive the active drawer section from the route that was active BEFORE
  // the drawer opened. When the drawer is visible, routeMirror is 'drawer_nav',
  // so we look at the route origin stack to find the previous real page.
  // When the drawer is NOT visible, routeMirror already holds the real page.
  private activeSection(): string {
    const raw: string = this.routeMirror;
    let name: string = raw;
    const colonIdx: number = raw.indexOf(':');
    if (colonIdx >= 0) name = raw.substring(0, colonIdx);
    // If we're on the drawer, the previous route tells us where the user came from.
    if (name === 'drawer_nav') {
      const stack: string[] = this.app().routeOriginStack;
      if (stack.length > 0) {
        const prev: string = stack[stack.length - 1];
        const prevColon: number = prev.indexOf(':');
        name = prevColon >= 0 ? prev.substring(0, prevColon) : prev;
      } else {
        name = 'main_grid_default';
      }
    }
    if (name.startsWith('main_') || name === 'drawer_nav') return 'main';
    if (name === 'archive' || name.startsWith('archive_')) return 'archive';
    if (name.startsWith('trash_') || name === 'trash') return 'trash';
    if (name.startsWith('notebook')) return 'notebooks';
    if (name.startsWith('tag')) return 'tags';
    if (name.startsWith('settings_')) return 'settings';
    if (name.startsWith('sync_')) return 'sync';
    if (name.startsWith('about')) return 'about';
    if (name.startsWith('search_')) return 'main';
    if (name.startsWith('editor_')) return 'main';
    return 'main';
  }

  @Builder row(label: string, icon: Resource, route: string, selected: boolean) {
    Row() {
      Image(icon).width(24).height(24)
        .fillColor(selected ? Style.accent : Style.icon)
        .margin({ right: 28 })
      Text(label).fontSize(16)
        .fontColor(selected ? Style.accent : Style.textPrimary)
        .fontWeight(selected ? FontWeight.Medium : FontWeight.Normal)
    }
    .width('100%').height(52).padding({ left: 16, right: 16 })
    .backgroundColor(selected ? Style.selectionBg : Color.Transparent)
    .borderRadius(selected ? 26 : 0)
    .key('drawer_row_' + route)
    .onClick(() => this.onNavigate(route))
  }

  build() {
    Stack() {
      Column()
        .width('100%').height('100%')
        .backgroundColor('#52000000')
        .onClick(() => this.onDismiss())
      Column() {
        // blue sync header
        Column() {
          Row() {
            Column() {
              Text('Syncing service').fontSize(16).fontWeight(FontWeight.Medium).fontColor(Style.textPrimary)
              Text('Disabled').fontSize(14).fontColor(Style.textSecondary).margin({ top: 2 })
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Image($r('app.media.ic_sync_settings')).width(26).height(26).fillColor(Style.textPrimary)
          }
          .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
        }
        .backgroundColor('#AACCF5')
        .width('100%')

        Scroll() {
          Column() {
            Text('Quillpad')
              .fontSize(24).fontWeight(FontWeight.Bold).fontColor(Style.accent)
              .width('100%').padding({ left: 16, top: 18, bottom: 14 })

            this.row('All Notes', $r('app.media.ic_notes'), 'main', this.activeSection() === 'main')
            this.row('Archive', $r('app.media.ic_archive'), 'archive', this.activeSection() === 'archive')
            this.row('Deleted', $r('app.media.ic_bin'), 'trash', this.activeSection() === 'trash')

            Divider().color(Style.divider).margin({ top: 8, bottom: 8 })
            Text('Notebooks').fontSize(14).fontColor(Style.textSecondary)
              .width('100%').padding({ left: 16, bottom: 6 })
            this.row('Your Notebooks', $r('app.media.ic_manage_notebooks'), 'notebooks', this.activeSection() === 'notebooks')
            this.row('No Notebook', $r('app.media.ic_notes'), 'notebook:__none__', false)
            ForEach(this.liveNotebooks(), (nb: Notebook) => {
              this.row(nb.name, $r('app.media.ic_notebook'), 'notebook:' + nb.name, false)
            }, (nb: Notebook) => 'nb' + nb.id + nb.name)

            Divider().color(Style.divider).margin({ top: 8, bottom: 8 })
            this.row('Tags', $r('app.media.ic_tag'), 'tags', this.activeSection() === 'tags')

            Divider().color(Style.divider).margin({ top: 8, bottom: 8 })
            this.row('Settings', $r('app.media.ic_settings'), 'settings', this.activeSection() === 'settings')
            this.row('About', $r('app.media.ic_about'), 'about', this.activeSection() === 'about')
          }
          .width('100%')
        }
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
      }
      .width('82%').height('100%')
      .backgroundColor('#FFFFFF')
    }
    .width('100%').height('100%')
    .alignContent(Alignment.TopStart)
  }
}
