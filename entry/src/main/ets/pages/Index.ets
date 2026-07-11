import { MainPage } from '../pages_feature/MainPage';
import { EditorPage } from '../pages_feature/EditorPage';
import { ArchivePage } from '../pages_feature/ArchivePage';
import { TrashPage } from '../pages_feature/TrashPage';
import { SearchPage } from '../pages_feature/SearchPage';
import { NotebooksPage } from '../pages_feature/NotebooksPage';
import { TagsPage } from '../pages_feature/TagsPage';
import { SettingsPage } from '../pages_feature/SettingsPage';
import { SyncPage } from '../pages_feature/SyncPage';
import { AboutPage } from '../pages_feature/AboutPage';
import { AppState } from '../state/AppState';

// Maps a public route name to the owning feature area.
function areaOf(state: string): string {
  if (state.startsWith('main_') || state === 'drawer_nav') return 'main';
  if (state.startsWith('editor_')) return 'editor';
  if (state === 'archive' || state.startsWith('archive_')) return 'archive';
  if (state.startsWith('trash_')) return 'trash';
  if (state.startsWith('search_')) return 'search';
  if (state.startsWith('notebook')) return 'notebooks';
  if (state.startsWith('tag')) return 'tags';
  if (state.startsWith('settings_')) return 'settings';
  if (state.startsWith('sync_')) return 'sync';
  if (state.startsWith('about_')) return 'about';
  return 'main';
}

@Entry
@Component
struct Index {
  // AppState owns the live route + everything else. The route string is
  // mirrored into AppStorage('qp_route') so any @StorageLink observer
  // re-renders when navigation changes.
  @StorageLink('qp_route') routeMirror: string = 'main_grid_default:';
  @StorageLink('qp_notes_version') notesVersion: number = 0;

  current(): string {
    // Returns the full route string including any :param suffix.
    // Pages (e.g. EditorPage) parse the param themselves.
    const raw: string = this.routeMirror;
    if (raw.length === 0) return 'main_grid_default';
    // Strip the trailing ':' added by AppState.publishAll when param is empty.
    if (raw.charAt(raw.length - 1) === ':') {
      return raw.substring(0, raw.length - 1);
    }
    return raw;
  }

  area(): string {
    const c: string = this.current();
    const idx: number = c.indexOf(':');
    const name: string = idx < 0 ? c : c.substring(0, idx);
    if (name.startsWith('main_') || name === 'drawer_nav') return 'main';
    if (name.startsWith('editor_')) return 'editor';
    if (name === 'archive' || name.startsWith('archive_')) return 'archive';
    if (name.startsWith('trash_')) return 'trash';
    if (name.startsWith('search_')) return 'search';
    if (name.startsWith('notebook')) return 'notebooks';
    if (name.startsWith('tag')) return 'tags';
    if (name.startsWith('settings_')) return 'settings';
    if (name.startsWith('sync_')) return 'sync';
    if (name.startsWith('about_')) return 'about';
    return 'main';
  }

  go = (route: string): void => {
    AppState.getInstance().go(route);
  };

  // System back: pop the AppState back stack if any, else fall through.
  onPageShow(): void {}
  onBackPress(): boolean {
    return AppState.getInstance().back();
  }

  build() {
    Column() {
      if (this.area() === 'main') {
        MainPage({ state: this.current(), go: this.go })
      } else if (this.area() === 'editor') {
        EditorPage({ state: this.current(), go: this.go })
      } else if (this.area() === 'archive') {
        ArchivePage({ state: this.current(), go: this.go })
      } else if (this.area() === 'trash') {
        TrashPage({ state: this.current(), go: this.go })
      } else if (this.area() === 'search') {
        SearchPage({ state: this.current(), go: this.go })
      } else if (this.area() === 'notebooks') {
        NotebooksPage({ state: this.current(), go: this.go })
      } else if (this.area() === 'tags') {
        TagsPage({ state: this.current(), go: this.go })
      } else if (this.area() === 'settings') {
        SettingsPage({ state: this.current(), go: this.go })
      } else if (this.area() === 'sync') {
        SyncPage({ state: this.current(), go: this.go })
      } else {
        AboutPage({ state: this.current(), go: this.go })
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#FFFFFF')
  }
}
