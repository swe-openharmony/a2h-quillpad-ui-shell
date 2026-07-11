import { Note, Notebook, TagItem, NoteColor, Task } from '../model/Data';
import { NOTES, ARCHIVED_NOTES, TRASHED_NOTES, NOTEBOOKS, TAGS } from '../model/Seed';

// Quillpad app-wide state container.
//
// Lives in AppStorage so any @StorageLink('qp_*') binding observes mutations.
// Truth owner for: notes[], notebooks[], tags[], prefs, selection, search,
// toast, navigation route, and per-route parameter (currentNotebookFilter,
// tagAssignmentNoteId, searchInitialQuery).

export enum SortKey { Title = 'title', Created = 'created', Modified = 'modified' }
export enum SortDir { Asc = 'asc', Desc = 'desc' }
export enum LayoutMode { Grid = 'grid', List = 'list' }
export enum ThemeMode { System = 'system', Dark = 'dark', Light = 'light' }
export enum DarkThemeMode { Standard = 'standard', Black = 'black' }
export enum ColorScheme { Blue = 'Blue', Red = 'Red', Yellow = 'Yellow',
  Green = 'Green', Pink = 'Pink', Orange = 'Orange', Purple = 'Purple' }
export enum FontSize { Default = 'Default', Small = 'Small', Medium = 'Medium',
  Large = 'Large', Huge = 'Huge' }
export enum EditorMode { View = 'view', Edit = 'edit' }
export enum ButtonPosition { Floating = 'floating', TopBar = 'topbar' }
export enum YesNo { Yes = 'Yes', No = 'No' }
export enum DateFormat { A = 'June 29 2026', B = '29 June 2026', C = '2026/06/29', D = '06/29/2026' }
export enum TimeFormat { Hour12 = '12-hour', Hour24 = '24-hour' }
export enum OpenMedia { Internal = 'Internal', External = 'External' }
export enum DeletionTime { Never = 'Never', Instantly = 'Instantly',
  After7Days = 'After 7 days', After2Weeks = 'After 2 weeks', After1Month = 'After 1 month' }
export enum BackupStrategy { Everything = 'Backup everything', SkipAttachments = 'Skip attachments' }
export enum SyncProvider { Disabled = 'Disabled', Nextcloud = 'Nextcloud', FileStorage = 'File Storage' }

export interface Prefs {
  themeMode: ThemeMode;
  darkThemeMode: DarkThemeMode;
  colorScheme: ColorScheme;
  layoutMode: LayoutMode;
  sortBy: SortKey;
  sortDir: SortDir;
  tagSortBy: SortKey;
  tagSortDir: SortDir;
  notebookSortBy: SortKey;
  notebookSortDir: SortDir;
  fontSize: FontSize;
  buttonPosition: ButtonPosition;
  defaultEditorMode: EditorMode;
  showDate: YesNo;
  dateFormat: DateFormat;
  timeFormat: TimeFormat;
  openMedia: OpenMedia;
  groupNoNotebook: YesNo;
  moveChecked: YesNo;
  deletionTime: DeletionTime;
  backupStrategy: BackupStrategy;
  syncProvider: SyncProvider;
  newNotesSyncable: YesNo;
  syncCredentialsConfigured: boolean;
}

export interface Route {
  name: string;          // e.g. 'main_grid_default', 'editor_view:3'
  param: string;         // for editor_view:3 -> "3"
}

function defPrefs(): Prefs {
  const p: Prefs = {
    themeMode: ThemeMode.System,
    darkThemeMode: DarkThemeMode.Standard,
    colorScheme: ColorScheme.Blue,
    layoutMode: LayoutMode.Grid,
    sortBy: SortKey.Modified,
    sortDir: SortDir.Desc,
    tagSortBy: SortKey.Title,
    tagSortDir: SortDir.Asc,
    notebookSortBy: SortKey.Title,
    notebookSortDir: SortDir.Asc,
    fontSize: FontSize.Default,
    buttonPosition: ButtonPosition.Floating,
    defaultEditorMode: EditorMode.View,
    showDate: YesNo.Yes,
    dateFormat: DateFormat.A,
    timeFormat: TimeFormat.Hour12,
    openMedia: OpenMedia.Internal,
    groupNoNotebook: YesNo.Yes,
    moveChecked: YesNo.Yes,
    deletionTime: DeletionTime.After7Days,
    backupStrategy: BackupStrategy.Everything,
    syncProvider: SyncProvider.Disabled,
    newNotesSyncable: YesNo.Yes,
    syncCredentialsConfigured: true,
  };
  return p;
}

function cloneNote(n: Note): Note {
  const tagsCopy: string[] = n.tags.slice();
  const tasksCopy: Task[] = n.tasks.map((t: Task): Task => {
    const copy: Task = { content: t.content, done: t.done };
    return copy;
  });
  return {
    id: n.id,
    title: n.title,
    content: n.content,
    isList: n.isList,
    tasks: tasksCopy,
    color: n.color,
    notebook: n.notebook,
    tags: tagsCopy,
    isPinned: n.isPinned,
    hasReminder: n.hasReminder,
    isMarkdown: n.isMarkdown,
    createdText: n.createdText,
    modifiedText: n.modifiedText,
    archived: n.archived,
    deleted: n.deleted,
    hidden: n.hidden === true,
    localOnly: n.localOnly === true,
    swatched: n.swatched === true,
  };
}

function cloneNotebook(nb: Notebook): Notebook {
  return { id: nb.id, name: nb.name };
}

function cloneTag(t: TagItem): TagItem {
  return { id: t.id, name: t.name };
}

const VERSION_KEY = 'qp_notes_version';
const NOTEBOOKS_KEY = 'qp_notebooks';
const TAGS_KEY = 'qp_tags';
const PREFS_KEY = 'qp_prefs';
const TOAST_KEY = 'qp_toast';
const ROUTE_KEY = 'qp_route';
const SELECTED_KEY = 'qp_selected';
const SEARCH_KEY = 'qp_search';
const SHOW_HIDDEN_KEY = 'qp_show_hidden';
const NOTEBOOK_FILTER_KEY = 'qp_notebook_filter';
const TAG_ASSIGN_KEY = 'qp_tag_assign_note';
const SEARCH_INIT_KEY = 'qp_search_init_query';
const NEXT_ID_KEY = 'qp_next_id';

export class AppState {
  private static inst: AppState | null = null;

  notes: Note[] = [];
  notebooks: Notebook[] = [];
  tags: TagItem[] = [];
  prefs: Prefs = defPrefs();
  toast: string = '';
  route: Route = { name: 'main_grid_default', param: '' };
  selectedIds: number[] = [];
  searchQuery: string = '';
  searchInitialQuery: string = '';
  showHidden: boolean = false;
  notebookFilter: string = '';        // '' = All Notes, '__none__' = no-notebook pseudo
  tagAssignmentNoteId: number = -1;
  nextId: number = 100;

  // Track the originating screen so route back behavior lands correctly.
  routeOriginStack: string[] = [];

  private constructor() {}

  static getInstance(): AppState {
    if (AppState.inst === null) {
      AppState.inst = new AppState();
    }
    return AppState.inst;
  }

  // ---------------------------------------------------------------
  // ---------------------------------------------------------------
  init(wantParams: Record<string, Object> | null): void {
    this.applySeed();
    this.applyWantParams(wantParams);
    this.publishAll();
  }

  applySeed(): void {
    this.notes = NOTES.map(cloneNote)
      .concat(ARCHIVED_NOTES.map(cloneNote))
      .concat(TRASHED_NOTES.map(cloneNote));
    this.notebooks = NOTEBOOKS.map(cloneNotebook);
    this.tags = TAGS.map(cloneTag);
    this.prefs = defPrefs();
    this.toast = '';
    this.route = { name: 'main_grid_default', param: '' };
    this.selectedIds = [];
    this.searchQuery = '';
    this.searchInitialQuery = '';
    this.showHidden = false;
    this.notebookFilter = '';
    this.tagAssignmentNoteId = -1;
    this.nextId = 100;
    this.routeOriginStack = [];
  }

  // (helper separator)

  applyWantParams(params: Record<string, Object> | null): void {
    if (!params) return;
    const getStr = (k: string): string | null => {
      const v: Object | undefined = params[k];
      if (typeof v === 'string') return v as string;
      return null;
    };

    const fixture: string | null = getStr('benchmark_fixture');
    if (fixture === 'empty_notes') {
      this.notes = [];
      this.notebooks = [];
      this.tags = [];
    }

    const surface: string | null = getStr('benchmark_surface');
    if (surface !== null && surface.length > 0) {
      if (surface === 'no_notebook') {
        this.notebookFilter = '__none__';
      }
      const routeName: string = this.routeForBenchmarkSurface(surface);
      if (routeName.length > 0) {
        this.route = parseRoute(routeName);
      }
    }
  }

  private routeForBenchmarkSurface(surface: string): string {
    if (surface === 'all_notes') return 'main_grid_default';
    if (surface === 'archive') return 'archive_populated';
    if (surface === 'trash') return 'trash_populated';
    if (surface === 'notebooks') return 'notebooks_list';
    if (surface === 'no_notebook') return 'notebook_notes';
    if (surface === 'tags') return 'tags_list';
    if (surface === 'settings') return 'settings_main_top';
    if (surface === 'search') return 'search_initial';
    if (surface === 'markdown_editor') return 'editor_view:2';
    if (surface === 'checklist_editor') return 'editor_view:3';
    if (surface === 'sync') return 'sync_main';
    return '';
  }

  publishAll(): void {
    this.bumpVersion();
  }

  bumpVersion(): void {
    AppStorage.setOrCreate<number>(NOTEBOOKS_KEY, this.notebooks.length);
    AppStorage.setOrCreate<number>(TAGS_KEY, this.tags.length);
    AppStorage.setOrCreate<string>(PREFS_KEY, this.prefsSignature());
    AppStorage.setOrCreate<string>(TOAST_KEY, this.toast);
    AppStorage.setOrCreate<string>(ROUTE_KEY, this.route.name + ':' + this.route.param);
    AppStorage.setOrCreate<number>(SELECTED_KEY, this.selectedIds.length);
    AppStorage.setOrCreate<string>(SEARCH_KEY, this.searchQuery);
    AppStorage.setOrCreate<boolean>(SHOW_HIDDEN_KEY, this.showHidden);
    AppStorage.setOrCreate<string>(NOTEBOOK_FILTER_KEY, this.notebookFilter);
    AppStorage.setOrCreate<number>(TAG_ASSIGN_KEY, this.tagAssignmentNoteId);
    AppStorage.setOrCreate<string>(SEARCH_INIT_KEY, this.searchInitialQuery);
    AppStorage.setOrCreate<number>(NEXT_ID_KEY, this.nextId);
    // Bump the global version last so any @StorageLink('qp_notes_version')
    // observer reads a consistent snapshot.
    const newVersion: number = this.currentVersion() + 1;
    AppStorage.setOrCreate<number>(VERSION_KEY, newVersion);
  }

  currentVersion(): number {
    const v: number | undefined = AppStorage.get<number>(VERSION_KEY);
    return v === undefined ? 0 : v;
  }

  prefsSignature(): string {
    // Compact representation so SettingsPage rows observe changes.
    const p: Prefs = this.prefs;
    return [
      p.themeMode, p.darkThemeMode, p.colorScheme, p.layoutMode,
      p.sortBy + ':' + p.sortDir, p.tagSortBy + ':' + p.tagSortDir,
      p.notebookSortBy + ':' + p.notebookSortDir, p.fontSize,
      p.buttonPosition, p.defaultEditorMode, p.showDate, p.dateFormat,
      p.timeFormat, p.openMedia, p.groupNoNotebook, p.moveChecked,
      p.deletionTime, p.backupStrategy, p.syncProvider, p.newNotesSyncable,
      p.syncCredentialsConfigured ? 'creds' : 'nocreds',
    ].join('|');
  }

  // ---------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------
  setPref(name: string, value: string, publish: boolean = true): void {
    this.refreshAfterAction();
  }

  private refreshAfterAction(message: string = 'Action recorded'): void {
    this.toast = message;
    this.bumpVersion();
  }

  // ----- navigation --------------------------------------------------
  go(route: string): void {
    // Push current route (with param) onto back stack so system back returns
    // to it. Skip if the new target equals the current route (idempotent nav).
    const curFull: string = this.route.name + (this.route.param.length > 0 ? ':' + this.route.param : '');
    if (curFull.length > 0 && route !== curFull) {
      this.routeOriginStack.push(curFull);
      if (this.routeOriginStack.length > 8) this.routeOriginStack.shift();
    }
    this.route = parseRoute(route);
    this.bumpVersion();
  }

  // Returns true if back was consumed (route changed).
  back(): boolean {
    if (this.routeOriginStack.length === 0) return false;
    const prev: string | undefined = this.routeOriginStack.pop();
    if (prev === undefined || prev.length === 0) return false;
    this.route = parseRoute(prev);
    this.bumpVersion();
    return true;
  }

  // ----- selection ---------------------------------------------------
  toggleSelected(id: number): void {
    const idx: number = this.selectedIds.indexOf(id);
    if (idx >= 0) {
      this.selectedIds.splice(idx, 1);
    } else {
      this.selectedIds.push(id);
    }
    this.bumpVersion();
  }

  selectAllVisible(ids: number[]): void {
    this.selectedIds = [];
    if (ids.length > 0) {
      this.selectedIds.push(ids[0]);
    }
    this.bumpVersion();
  }

  clearSelection(): void {
    this.selectedIds = [];
    this.bumpVersion();
  }

  isSelected(id: number): boolean {
    return this.selectedIds.indexOf(id) >= 0;
  }

  selectedCount(): number {
    return this.selectedIds.length;
  }

  // ----- notes -------------------------------------------------------
  noteById(id: number): Note | null {
    for (let i = 0; i < this.notes.length; i++) {
      if (this.notes[i].id === id) return this.notes[i];
    }
    return null;
  }

  activeNotes(): Note[] {
    return this.notes.filter((n: Note) => !n.archived && !n.deleted);
  }
  archivedNotes(): Note[] {
    return this.notes.filter((n: Note) => n.archived && !n.deleted);
  }
  trashedNotes(): Note[] {
    return this.notes.filter((n: Note) => n.deleted);
  }

  // Notes visible on the All-notes list, after applying showHidden + sort.
  visibleMainNotes(): Note[] {
    const arr: Note[] = this.activeNotes().filter((n: Note) => {
      if (n.hidden === true && !this.showHidden) return false;
      return true;
    });
    return this.applySort(arr, this.prefs.sortBy, this.prefs.sortDir);
  }

  // Notes for a notebook filter (real notebook name or '__none__').
  visibleNotebookNotes(name: string): Note[] {
    const arr: Note[] = this.activeNotes().filter((n: Note) => {
      const nb: string | null = n.notebook;
      const matches: boolean = name === '__none__'
        ? (nb === null || nb === '')
        : nb === name;
      if (!matches) return false;
      if (n.hidden === true && !this.showHidden) return false;
      return true;
    });
    return this.applySort(arr, this.prefs.sortBy, this.prefs.sortDir);
  }

  private applySort(arr: Note[], _key: SortKey, _dir: SortDir): Note[] {
    // The public shell preserves fixture order; sorting is implementation work.
    return arr.slice();
  }

  createNote(): Note {
    const n: Note = {
      id: this.nextId,
      title: '',
      content: '',
      isList: false,
      tasks: [],
      color: NoteColor.Default,
      notebook: null,
      tags: [],
      isPinned: false,
      hasReminder: false,
      isMarkdown: false,
      createdText: 'Created at June 29 2026, 12:11',
      modifiedText: 'Last modified at June 29 2026, 12:11',
      archived: false,
      deleted: false,
    };
    this.refreshAfterAction();
    return n;
  }

  // Public shell action entry points intentionally leave note data unchanged.
  updateNote(_id: number, _mut: (n: Note) => void): void { this.bumpVersion(); }
  togglePinned(_id: number): void { this.bumpVersion(); }
  toggleHidden(_id: number): void { this.bumpVersion(); }
  toggleLocalOnly(_id: number): void { this.bumpVersion(); }
  toggleMarkdown(_id: number): void { this.bumpVersion(); }
  setNoteColor(_id: number, _color: NoteColor): void { this.bumpVersion(); }
  setNoteTitle(_id: number, _title: string): void { this.bumpVersion(); }
  setNoteContent(_id: number, _content: string): void { this.bumpVersion(); }
  setNoteNotebook(_id: number, _name: string | null): void { this.bumpVersion(); }
  toggleNoteTag(_id: number, _tagName: string): void { this.bumpVersion(); }
  convertToList(_id: number): void { this.bumpVersion(); }
  convertToText(_id: number): void { this.bumpVersion(); }
  uncheckAllTasks(_id: number): void { this.bumpVersion(); }
  removeAllCheckedTasks(_id: number): void { this.bumpVersion(); }
  addTaskAt(_id: number, _position: number, _content: string): void { this.bumpVersion(); }
  setTaskContent(_id: number, _index: number, _content: string): void { this.bumpVersion(); }
  removeTask(_id: number, _index: number): void { this.bumpVersion(); }
  toggleTask(_id: number, _index: number): void { this.bumpVersion(); }

  archiveSelected(): string {
    this.clearSelection();
    this.refreshAfterAction();
    return this.toast;
  }

  unarchiveSelected(): string {
    this.clearSelection();
    this.refreshAfterAction();
    return this.toast;
  }

  // Returns 'moved-to-bin' or 'deleted-permanently' depending on deletionTime.
  deleteSelected(): string {
    this.clearSelection();
    this.refreshAfterAction();
    return this.toast;
  }

  restoreSelected(): string {
    this.clearSelection();
    this.refreshAfterAction();
    return this.toast;
  }

  deleteSelectedPermanently(): string {
    this.clearSelection();
    this.refreshAfterAction();
    return this.toast;
  }

  emptyBin(): void {
    this.refreshAfterAction();
  }

  duplicateSelected(): string {
    this.clearSelection();
    this.refreshAfterAction();
    return this.toast;
  }

  moveSelectedToNotebook(_notebook: string | null): string {
    this.clearSelection();
    return this.toast;
  }

  // ----- notebooks ---------------------------------------------------
  createNotebook(name: string): string {
    this.refreshAfterAction();
    return this.toast;
  }

  renameNotebook(id: number, name: string): string {
    this.refreshAfterAction();
    return this.toast;
  }

  deleteNotebook(id: number): void {
    this.refreshAfterAction();
  }

  sortedNotebooks(): Notebook[] {
    return this.notebooks.slice();
  }

  // ----- tags --------------------------------------------------------
  createTag(name: string): string {
    this.refreshAfterAction();
    return this.toast;
  }

  renameTag(id: number, name: string): string {
    this.refreshAfterAction();
    return this.toast;
  }

  deleteTag(id: number): void {
    this.refreshAfterAction();
  }

  sortedTags(): TagItem[] {
    return this.tags.slice();
  }

  // ----- search ------------------------------------------------------
  runSearch(query: string): Note[] {
    this.searchQuery = query;
    this.refreshAfterAction();
    return [];
  }

  // ----- toast -------------------------------------------------------
  showToast(msg: string): void {
    this.toast = msg;
    this.bumpVersion();
  }

  clearToast(): void {
    this.toast = '';
    this.bumpVersion();
  }

  dumpState(): string {
    // Backup serialization is intentionally absent from the public shell.
    return '';
  }

  loadState(_json: string): void {
    // Backup restore is intentionally absent from the public shell.
  }
}

// Route string -> { name, param }. e.g. "editor_view:3" -> { name: 'editor_view', param: '3' }.
export function parseRoute(s: string): Route {
  const idx: number = s.indexOf(':');
  if (idx < 0) return { name: s, param: '' };
  return { name: s.substring(0, idx), param: s.substring(idx + 1) };
}

// Bundle-version helper for AboutPage.
export function appVersionDisplay(): string {
  return '1.5.12';
}
