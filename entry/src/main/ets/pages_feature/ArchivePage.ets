import { TopBar, IconButton } from '../components/Common';
import { NoteCard } from '../components/NoteCard';
import { BottomSheet, PopupMenu, MenuRow } from '../components/Overlays';
import { Note } from '../model/Data';
import { AppState } from '../state/AppState';
import { promptAction } from '@kit.ArkUI';

// Archive feature area. Covers states:
// archive_populated, archive_selection (per-note context BottomSheet),
// archive_overflow, archive_sort, archive_move_dialog.
@Component
export struct ArchivePage {
  @Prop state: string;
  go: (route: string) => void = () => {};

  @StorageLink('qp_notes_version') notesVersion: number = 0;
  // These controls model only the currently visible shell; no fixture data is changed.
  @State private selectedCount: number = 0;
  @State private showHidden: boolean = false;
  @State private hiddenNoteId: number = -1;
  @State private contextNoteId: number = 7;

  private app(): AppState { return AppState.getInstance(); }

  private notesList(): Note[] {
    return this.app().archivedNotes().filter((n: Note) => {
      return this.showHidden || n.id !== this.hiddenNoteId;
    });
  }

  private contextRows(): MenuRow[] {
    return [
      { label: 'Unarchive', icon: $r('app.media.ic_unarchive') },
      { label: 'Delete', icon: $r('app.media.ic_bin') },
      { label: 'Hide', icon: $r('app.media.ic_hidden') },
      { label: 'Compact preview', icon: $r('app.media.ic_preview') },
      { label: 'Enable screen always on', icon: $r('app.media.ic_pin') },
      { label: 'Enable markdown', icon: $r('app.media.ic_markdown') },
      { label: 'Export', icon: $r('app.media.ic_export_note') },
      { label: 'Share', icon: $r('app.media.ic_share') },
      { label: 'Select more…', icon: $r('app.media.ic_select_more') },
    ];
  }

  private overflowRows(): MenuRow[] {
    return [
      { label: 'Show hidden notes', trailing: 'checkbox', checked: this.showHidden },
      { label: 'Select All' },
    ];
  }

  private notify(msg: string): void {
    try { promptAction.showToast({ message: msg, duration: 1500 }); } catch (e) {}
  }

  private selectAllVisible(): void {
    this.selectedCount = this.notesList().length;
  }

  private handleOverflow(label: string): void {
    if (label === 'Show hidden notes') {
      this.showHidden = !this.showHidden;
    } else if (label === 'Select All') {
      this.selectAllVisible();
    }
    this.go(this.selectedCount > 0 ? 'archive_selection' : 'archive_populated');
  }

  private handleContext(label: string): void {
    // Action labels are intentionally present for contract reachability only.
    // Picking one dismisses its temporary surface without changing archive data.
    if (label === 'Select more…') this.selectedCount = 1;
    this.go(this.selectedCount > 0 ? 'archive_selection' : 'archive_populated');
  }

  @Builder selectionToolbar() {
    TopBar({ leading: $r('app.media.ic_back'), title: 'Selected ' + this.selectedTitleSuffix(),
      onLeading: () => { this.selectedCount = 0; this.go('archive_populated'); } }) {
      IconButton({ icon: $r('app.media.ic_select_more'), keyId: 'toolbar_more', onTap: () => this.go('archive_overflow') })
    }
  }

  @Builder normalToolbar() {
    TopBar({ leading: $r('app.media.ic_notes'), title: 'Archive',
      onLeading: () => this.go('drawer_nav') }) {
      IconButton({ icon: $r('app.media.ic_search'), keyId: 'toolbar_search', onTap: () => this.go('search_initial') })
      IconButton({ icon: $r('app.media.ic_select_more'), keyId: 'toolbar_more', onTap: () => this.go('archive_overflow') })
    }
  }

  private selectedTitleSuffix(): string {
    const n: number = this.selectedCount;
    return n + (n === 1 ? ' note' : ' notes');
  }

  @Builder emptyState() {
    Column() {
      Image($r('app.media.ic_archive'))
        .width(96).height(96).fillColor('#CCCCCC')
      Text('Archived notes will appear here.')
        .fontSize(16).fontColor('#888888')
        .margin({ top: 20 })
    }
    .width('100%').layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder list() {
    if (this.notesList().length === 0) {
      this.emptyState()
    } else {
      List({ space: 12 }) {
        ForEach(this.notesList(), (n: Note) => {
          ListItem() {
            NoteCard({
              note: n,
              selected: this.selectedCount > 0,
              onTap: () => this.go('editor_view:' + n.id),
              onLongPress: () => {
                this.contextNoteId = n.id;
                this.go('archive_selection');
              }
            })
          }
          .key('archive_card_' + n.id)
        }, (n: Note) => 'a' + n.id + '_' + this.notesVersion)
      }
      .layoutWeight(1).padding(12)
    }
  }

  build() {
    Stack() {
      Column() {
        if (this.selectedCount > 0) {
          this.selectionToolbar()
        } else {
          this.normalToolbar()
        }
        this.list()
      }
      .width('100%').height('100%')

      if (this.state === 'archive_selection') {
        BottomSheet({ header: this.contextHeader(), rows: this.contextRows(),
          onPick: (index: number) => this.handleContext(this.contextRows()[index].label),
          onDismiss: () => this.go('archive_populated') })
      }
      if (this.state === 'archive_overflow') {
        PopupMenu({ rows: this.overflowRows(), top: 0, menuWidthPct: 72, rowHeight: 60,
          onPick: (index: number) => this.handleOverflow(this.overflowRows()[index].label),
          onDismiss: () => this.go(this.selectedCount > 0 ? 'archive_selection' : 'archive_populated') })
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#FFFFFF')
  }

  private contextHeader(): string {
    const n: Note | null = this.app().noteById(this.contextNoteId);
    return n === null ? '' : (n as Note).title;
  }
}
