import { Style } from '../components/Style';
import { TopBar, IconButton } from '../components/Common';
import { NoteCard } from '../components/NoteCard';
import { DialogCard, BottomSheet, PopupMenu, MenuRow } from '../components/Overlays';
import { Note, noteColorHex, NoteColor } from '../model/Data';
import { AppState } from '../state/AppState';
import { promptAction } from '@kit.ArkUI';

@Component
struct MoreVertIcon {
  @Prop color: string = Style.textPrimary;

  build() {
    Column({ space: 3 }) {
      Circle({ width: 4, height: 4 }).fill(this.color)
      Circle({ width: 4, height: 4 }).fill(this.color)
      Circle({ width: 4, height: 4 }).fill(this.color)
    }
    .width(24)
    .height(24)
    .justifyContent(FlexAlign.Center)
  }
}

@Component
export struct TrashPage {
  @Prop state: string;
  go: (route: string) => void = () => {};

  @StorageLink('qp_notes_version') notesVersion: number = 0;
  // UI-shell-only presentation state; actions never alter the seeded bin.
  @State private selectedCount: number = 0;
  @State private showHidden: boolean = false;
  @State private hiddenNoteId: number = -1;
  @State private contextNoteId: number = 8;

  private app(): AppState { return AppState.getInstance(); }

  private retentionLabel(): string {
    return 'After 7 days';
  }

  private notesList(): Note[] {
    return this.app().trashedNotes().filter((n: Note) => {
      return this.showHidden || n.id !== this.hiddenNoteId;
    });
  }

  private contextRows(): MenuRow[] {
    return [
      { label: 'Restore', icon: $r('app.media.ic_restore') },
      { label: 'Delete permanently', icon: $r('app.media.ic_bin') },
      { label: 'Show / Hide', icon: $r('app.media.ic_hidden') },
      { label: 'Export', icon: $r('app.media.ic_export_note') },
      { label: 'Share', icon: $r('app.media.ic_share') },
      { label: 'Select more…', icon: $r('app.media.ic_select_more') },
    ];
  }

  private overflowRows(): MenuRow[] {
    return [
      { label: 'Show hidden notes', trailing: 'checkbox', checked: this.showHidden },
      { label: 'Select All' },
      { label: 'Empty bin' },
    ];
  }

  private notify(msg: string): void {
    try { promptAction.showToast({ message: msg, duration: 1500 }); } catch (e) {}
  }

  private selectAllVisible(): void {
    this.selectedCount = this.notesList().length;
  }

  private handleOverflow(label: string): void {
    if (label === 'Empty bin') {
      this.go('trash_empty_bin_confirm');
      return;
    }
    if (label === 'Show hidden notes') this.showHidden = !this.showHidden;
    if (label === 'Select All') this.selectAllVisible();
    this.go(this.selectedCount > 0 ? 'trash_selection' : 'trash_populated');
  }

  private handleContext(label: string): void {
    // Restore/delete are inert shell affordances. Only Hide changes what this
    // page renders, and even that state is discarded with the page instance.
    if (label === 'Show / Hide') this.hiddenNoteId = this.contextNoteId;
    if (label === 'Select more…') this.selectedCount = 1;
    this.go(this.selectedCount > 0 ? 'trash_selection' : 'trash_populated');
  }

  private trashListNote(note: Note): Note {
    return {
      id: note.id,
      title: note.title,
      content: note.content,
      isList: note.isList,
      tasks: note.tasks,
      color: NoteColor.Red,
      notebook: note.notebook,
      tags: note.tags,
      isPinned: note.isPinned,
      hasReminder: note.hasReminder,
      isMarkdown: note.isMarkdown,
      createdText: note.createdText,
      modifiedText: note.modifiedText,
      archived: note.archived,
      deleted: note.deleted
    };
  }

  @Builder selectionToolbar() {
    TopBar({ leading: $r('app.media.ic_back'), title: 'Selected ' + this.selectedTitleSuffix(),
      onLeading: () => { this.selectedCount = 0; this.go('trash_populated'); } }) {
      IconButton({ icon: $r('app.media.ic_select_more'), keyId: 'toolbar_more', onTap: () => this.go('trash_overflow') })
    }
  }

  @Builder normalToolbar() {
    TopBar({ leading: $r('app.media.ic_notes'), title: 'Deleted',
      onLeading: () => this.go('drawer_nav') }) {
      IconButton({ icon: $r('app.media.ic_search'), keyId: 'toolbar_search', onTap: () => this.go('search_initial') })
      IconButton({ icon: $r('app.media.ic_select_more'), keyId: 'toolbar_more', onTap: () => this.go('trash_overflow') })
    }
  }

  private selectedTitleSuffix(): string {
    const n: number = this.selectedCount;
    return n + (n === 1 ? ' note' : ' notes');
  }

  // (placeholder to keep struct ordering intact)

  @Builder retentionRow() {
    Row() {
      Text('Notes are deleted ' + this.retentionLabel().toLowerCase() + '.')
        .fontSize(14).fontColor(Style.textSecondary).layoutWeight(1)
    }
    .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder emptyState() {
    Column() {
      Image($r('app.media.ic_bin'))
        .width(96).height(96).fillColor('#CCCCCC')
      Text('Deleted notes will appear here.')
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
        ListItem() { this.retentionRow() }
        ForEach(this.notesList(), (n: Note) => {
          ListItem() {
            NoteCard({
              note: this.trashListNote(n),
              forceColorFill: true,
              selected: this.selectedCount > 0,
              onTap: () => {
                this.contextNoteId = n.id;
                this.go('trash_view_only');
              },
              onLongPress: () => {
                this.contextNoteId = n.id;
                this.go('trash_context');
              }
            })
          }
          .key('trash_card_' + n.id)
        }, (n: Note) => 't' + n.id + '_' + this.notesVersion)
      }
      .layoutWeight(1).padding(12)
    }
  }

  @Builder overflowButton(onTap: () => void) {
    Button({ type: ButtonType.Circle, stateEffect: false }) {
      MoreVertIcon({ color: Style.textPrimary })
    }
    .backgroundColor(Color.Transparent)
    .width(44)
    .height(44)
    .onClick(() => onTap())
  }

  @Builder viewOnly() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Row() {
          IconButton({ icon: $r('app.media.ic_back'), tint: Style.textPrimary,
            onTap: () => this.go('trash_populated') })
            .margin({ left: 4, right: 8 })
          Row() {
            Image($r('app.media.ic_notebook')).width(20).height(20)
              .fillColor(Style.textPrimary).margin({ right: 10 })
            Text('No Notebook').fontSize(16).fontColor(Style.textPrimary)
              .fontWeight(FontWeight.Medium)
            Image($r('app.media.ic_add')).width(20).height(20)
              .fillColor(Style.textPrimary).margin({ left: 10 })
          }
          .border({ width: 1, color: Style.chipBorder, radius: 24 })
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          IconButton({ icon: $r('app.media.ic_restore'), tint: Style.textPrimary, onTap: () => {
            this.go('trash_populated');
          } })
          this.overflowButton(() => this.go('trash_context'))
        }
        .width('100%').height(Style.toolbarHeight)
        .padding({ right: 4 })
        .alignItems(VerticalAlign.Center)

        Column() {
          Text(this.contextNote().title)
            .fontSize(26).fontWeight(FontWeight.Bold).fontColor(Style.textPrimary)
            .width('100%').margin({ top: 12, bottom: 18 })
          Text(this.contextNote().content)
            .fontSize(18).fontColor(Style.textPrimary)
            .width('100%').margin({ bottom: 28 })
          Text(this.contextNote().createdText)
            .fontSize(15).fontColor(Style.textSecondary).fontStyle(FontStyle.Italic)
            .width('100%')
          Text(this.contextNote().modifiedText)
            .fontSize(15).fontColor(Style.textSecondary).fontStyle(FontStyle.Italic)
            .width('100%').margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .width('100%').height('100%')

      Row() {
        Text('Notes inside the bin cannot be edited.')
          .fontSize(16).fontColor('#FFFFFF').layoutWeight(1)
        Text('RESTORE')
          .fontSize(16).fontColor(Style.accent).fontWeight(FontWeight.Medium)
          .margin({ left: 16 })
          .onClick(() => {
            this.go('trash_populated');
          })
      }
      .width('92%')
      .padding({ left: 20, right: 20, top: 18, bottom: 18 })
      .margin({ bottom: 36 })
      .backgroundColor('#323232')
      .borderRadius(6)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%').height('100%')
    .backgroundColor(noteColorHex(NoteColor.Pink))
  }

  private contextNote(): Note {
    const n: Note | null = this.app().noteById(this.contextNoteId);
    if (n === null) return this.fallback();
    return n as Note;
  }
  private fallback(): Note {
    return {
      id: 8, title: '', content: '', isList: false, tasks: [], color: NoteColor.Default,
      notebook: null, tags: [], isPinned: false, hasReminder: false, isMarkdown: false,
      createdText: '', modifiedText: '', archived: false, deleted: true,
    };
  }

  @Builder confirmBody() {
    Text('All deleted notes will be lost.')
      .fontSize(16).fontColor(Style.textSecondary).width('100%')
  }

  @Builder confirmActions() {
    Button('NO')
      .fontSize(16).fontColor(Style.accent).fontWeight(FontWeight.Medium)
      .backgroundColor(Color.Transparent)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .key('dialog_no')
      .onClick(() => this.go('trash_populated'))
    Button('YES')
      .fontSize(16).fontColor(Style.accent).fontWeight(FontWeight.Medium)
      .backgroundColor(Color.Transparent)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .margin({ left: 8 })
      .key('dialog_yes')
      .onClick(() => this.go('trash_populated'))
  }

  build() {
    Stack() {
      if (this.state === 'trash_view_only') {
        this.viewOnly()
      } else {
        Column() {
          if (this.selectedCount > 0) {
            this.selectionToolbar()
          } else {
            this.normalToolbar()
          }
          this.list()
        }
        .width('100%').height('100%')

        if (this.state === 'trash_empty_bin_confirm') {
          DialogCard({ title: 'Are you sure?',
            body: () => { this.confirmBody() },
            actions: () => { this.confirmActions() },
            onDismiss: () => this.go('trash_populated') })
        }
        if (this.state === 'trash_overflow') {
          PopupMenu({ rows: this.overflowRows(), top: 0, menuWidthPct: 72, rowHeight: 60,
            onPick: (index: number) => this.handleOverflow(this.overflowRows()[index].label),
            onDismiss: () => this.go(this.selectedCount > 0 ? 'trash_selection' : 'trash_populated') })
        }
        if (this.state === 'trash_context') {
          BottomSheet({ header: this.contextNote().title, rows: this.contextRows(),
            onPick: (index: number) => this.handleContext(this.contextRows()[index].label),
            onDismiss: () => this.go('trash_populated') })
        }
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#FFFFFF')
  }
}
