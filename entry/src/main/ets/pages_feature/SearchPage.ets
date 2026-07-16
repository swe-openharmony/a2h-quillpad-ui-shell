import { Style } from '../components/Style';
import { IconButton } from '../components/Common';
import { NoteCard } from '../components/NoteCard';
import { BottomSheet, MenuRow } from '../components/Overlays';
import { Note } from '../model/Data';
import { AppState } from '../state/AppState';

// Search feature area. Covers states:
// search_initial, search_query (live query), search_prefilled:<tagname>.
@Component
export struct SearchPage {
  @Prop state: string;
  go: (route: string) => void = () => {};

  @StorageLink('qp_notes_version') notesVersion: number = 0;
  @StorageLink('qp_search') queryMirror: string = '';
  @StorageLink('qp_search_init_query') initialQueryMirror: string = '';
  @State private typed: string = '';
  @State private contextNoteId: number = 0;

  private app(): AppState { return AppState.getInstance(); }

  private prefilledQuery(): string {
    if (this.state.indexOf('search_prefilled:') === 0) {
      return this.state.substring('search_prefilled:'.length);
    }
    return '';
  }

  isPrefilled(): boolean {
    return this.state.indexOf('search_prefilled:') === 0;
  }

  private activeQuery(): string {
    if (this.isPrefilled()) return this.prefilledQuery();
    if (this.typed.length > 0) return this.typed;
    return this.app().searchQuery;
  }

  private results(): Note[] {
    const q: string = this.activeQuery();
    return this.app().runSearch(q);
  }

  private contextRows(): MenuRow[] {
    return [
      { label: 'Archive', icon: $r('app.media.ic_archive') },
      { label: 'Delete', icon: $r('app.media.ic_bin') },
      { label: 'Hide', icon: $r('app.media.ic_hidden') },
      { label: 'Export', icon: $r('app.media.ic_export_note') },
      { label: 'Share', icon: $r('app.media.ic_share') },
    ];
  }

  @Builder searchToolbar() {
    Row() {
      IconButton({ icon: $r('app.media.ic_back'), onTap: () => this.go('main_grid_default') })
        .margin({ left: 4, right: 8 })
      TextInput({ placeholder: 'Search…', text: this.activeQuery() })
        .placeholderColor(Style.textSecondary)
        .fontColor(Style.textPrimary)
        .fontSize(Style.bodySize)
        .caretColor(Style.accent)
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .padding({ left: 0 })
        .layoutWeight(1)
        .key('search_input')
        .onChange((value: string) => { this.typed = value; this.app().runSearch(value); })
    }
    .width('100%')
    .height(Style.toolbarHeight)
    .padding({ right: 4 })
    .backgroundColor(Style.bg)
    .alignItems(VerticalAlign.Center)
    .border({ width: { bottom: 1 }, color: Style.divider })
  }

  @Builder emptyBody() {
    Column() {
      Image($r('app.media.ic_search'))
        .width(96).height(96)
        .fillColor(Style.accent)
        .objectFit(ImageFit.Contain)
      Text('Search results will be displayed here.')
        .fontSize(16)
        .fontColor(Style.textSecondary)
        .margin({ top: 20 })
    }
    .layoutWeight(1)
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder noResultsBody() {
    Column() {
      Text('No results found.')
        .fontSize(16)
        .fontColor(Style.textSecondary)
        .margin({ top: 40 })
    }
    .layoutWeight(1)
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder resultsBody() {
    List({ space: 12 }) {
      ForEach(this.results(), (n: Note) => {
        ListItem() {
          NoteCard({
            note: n,
            onTap: () => this.go('editor_view:' + n.id),
            onLongPress: () => {
              this.contextNoteId = n.id;
              this.go('search_context');
            }
          })
        }
        .key('search_card_' + n.id)
        .gesture(
          LongPressGesture({ repeat: false, duration: 500 })
            .onAction(() => {
              this.contextNoteId = n.id;
              this.go('search_context');
            })
        )
      }, (n: Note) => 's' + n.id + '_' + this.notesVersion)
    }
    .layoutWeight(1)
    .padding(12)
  }

  private contextHeader(): string {
    const n: Note | null = this.app().noteById(this.contextNoteId);
    return n === null ? '' : (n as Note).title;
  }

  private handleContext(label: string): void {
    const id: number = this.contextNoteId;
    if (label === 'Archive') {
      this.app().selectedIds = [id];
      this.app().archiveSelected();
      this.go('search_query');
      return;
    }
    if (label === 'Delete') {
      this.app().selectedIds = [id];
      this.app().deleteSelected();
      this.go('search_query');
      return;
    }
    if (label === 'Hide') {
      this.app().toggleHidden(id);
      this.go('search_query');
      return;
    }
    this.go('search_query');
  }

  build() {
    Stack() {
      Column() {
        this.searchToolbar()
        if (this.activeQuery().length === 0) {
          this.emptyBody()
        } else if (this.results().length === 0) {
          this.noResultsBody()
        } else {
          this.resultsBody()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Style.bg)

      if (this.state === 'search_context') {
        BottomSheet({ header: this.contextHeader(), rows: this.contextRows(),
          onPick: (index: number) => this.handleContext(this.contextRows()[index].label),
          onDismiss: () => this.go('search_query') })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Style.bg)
  }
}
