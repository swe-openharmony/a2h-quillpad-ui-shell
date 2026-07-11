import { Note, Notebook, TagItem, NoteColor, Task } from './Data';

// Main list order EXACTLY as Android page_01 view.xml:
// Quarterly planning(pinned,Blue,Work) -> Project Roadmap(markdown,Green,Work,#ideas)
// -> Shopping List(checklist,Personal,#todo) -> Call the dentist(Yellow,Personal,#todo+#urgent,reminder)
// -> Reading list(no notebook) -> Gift ideas(Purple,no notebook)

export const NOTEBOOKS: Notebook[] = [
  { id: 1, name: 'Personal' },
  { id: 2, name: 'Work' }
];

export const TAGS: TagItem[] = [
  { id: 1, name: 'ideas' },
  { id: 2, name: 'todo' },
  { id: 3, name: 'urgent' }
];

const SHOPPING_TASKS: Task[] = [
  { content: 'Milk', done: true },
  { content: 'Bread', done: false },
  { content: 'Eggs', done: true },
  { content: 'Coffee beans', done: false },
  { content: 'Olive oil', done: false }
];

export const NOTES: Note[] = [
  {
    id: 1, title: 'Quarterly planning',
    content: 'Kick off Q3 planning. Align roadmap with the design team and lock scope by Friday.',
    isList: false, tasks: [], color: NoteColor.Blue, notebook: 'Work', tags: [],
    isPinned: true, hasReminder: false, isMarkdown: false,
    createdText: 'Created at October 14 +56458, 08:53',
    modifiedText: 'Last modified at August 21 +56461, 00:53',
    archived: false, deleted: false
  },
  {
    id: 2, title: 'Project Roadmap',
    // Mirrored VERBATIM from Android ui_info/page_01_main_list_grid/view.xml and
    // page_02_main_list_linear/view.xml text_view_content for note id=2
    // (Project Roadmap). Android keeps the raw markdown source characters
    // (## heading, - bullets, > quote) in the TextView without rendering styled
    // children, so Harmony NoteCard must render the same raw string verbatim.
    content: 'Roadmap\n\n## Milestones\n- Alpha ready by July\n- Beta in  August \n\n> Ship the MVP first.\n\nSee docs for details.',
    isList: false, tasks: [], color: NoteColor.Green, notebook: 'Work', tags: ['ideas'],
    isPinned: false, hasReminder: false, isMarkdown: true,
    createdText: 'Created at August 13 +56455, 23:06',
    modifiedText: 'Last modified at April 27 +56461, 07:06',
    archived: false, deleted: false
  },
  {
    id: 3, title: 'Shopping List',
    content: '', isList: true, tasks: SHOPPING_TASKS, color: NoteColor.Default,
    notebook: 'Personal', tags: ['todo'],
    isPinned: false, hasReminder: false, isMarkdown: false,
    createdText: 'Created at June 12 +56452, 13:20',
    modifiedText: 'Last modified at January 1 +56461, 13:20',
    archived: false, deleted: false
  },
  {
    id: 4, title: 'Call the dentist',
    content: 'Book a cleaning appointment for next week. Ask about the evening slots.',
    isList: false, tasks: [], color: NoteColor.Yellow, notebook: 'Personal', tags: ['todo', 'urgent'],
    isPinned: false, hasReminder: true, isMarkdown: false,
    createdText: 'Created at March 2 2026, 09:00',
    modifiedText: 'Last modified at March 2 2026, 09:00',
    archived: false, deleted: false
  },
  {
    id: 5, title: 'Reading list',
    content: 'Books to read this summer: Project Hail Mary, The Pragmatic Programmer, Designing Data-Intensive Applications.',
    isList: false, tasks: [], color: NoteColor.Default, notebook: null, tags: [],
    isPinned: false, hasReminder: false, isMarkdown: false,
    createdText: 'Created at May 1 2026, 10:00',
    modifiedText: 'Last modified at May 1 2026, 10:00',
    archived: false, deleted: false
  },
  {
    id: 6, title: 'Gift ideas',
    content: 'Headphones, a good notebook, a plant for the desk.',
    isList: false, tasks: [], color: NoteColor.Purple, notebook: null, tags: [],
    isPinned: false, hasReminder: false, isMarkdown: false,
    createdText: 'Created at April 1 2026, 10:00',
    modifiedText: 'Last modified at April 1 2026, 10:00',
    archived: false, deleted: false
  }
];

export const ARCHIVED_NOTES: Note[] = [
  {
    id: 7, title: 'Old meeting notes',
    content: 'Notes from the March all-hands. Action items resolved.',
    isList: false, tasks: [], color: NoteColor.Default, notebook: null, tags: [],
    isPinned: false, hasReminder: false, isMarkdown: false,
    createdText: 'Created at March 10 2026, 14:00',
    modifiedText: 'Last modified at March 10 2026, 14:00',
    archived: true, deleted: false
  },
  {
    id: 9, title: 'Archived reference',
    content: 'A second archived note used to make multi-selection observable.',
    isList: false, tasks: [], color: NoteColor.Default, notebook: 'Personal', tags: [],
    isPinned: false, hasReminder: false, isMarkdown: false,
    createdText: 'Created at February 18 2026, 11:30',
    modifiedText: 'Last modified at February 18 2026, 11:30',
    archived: true, deleted: false
  }
];

export const TRASHED_NOTES: Note[] = [
  {
    id: 8, title: 'Draft idea',
    content: 'A rough draft that did not pan out.',
    isList: false, tasks: [], color: NoteColor.Default, notebook: null, tags: [],
    isPinned: false, hasReminder: false, isMarkdown: false,
    createdText: 'Created at June 3 +56414, 16:00',
    modifiedText: 'Last modified at April 7 +56430, 16:53',
    archived: false, deleted: true
  },
  {
    id: 10, title: 'Discarded outline',
    content: 'A second deleted note used to make multi-selection observable.',
    isList: false, tasks: [], color: NoteColor.Default, notebook: null, tags: [],
    isPinned: false, hasReminder: false, isMarkdown: false,
    createdText: 'Created at January 12 2026, 15:45',
    modifiedText: 'Last modified at January 12 2026, 15:45',
    archived: false, deleted: true
  }
];

export function noteById(id: number): Note {
  const all: Note[] = NOTES.concat(ARCHIVED_NOTES).concat(TRASHED_NOTES);
  for (const n of all) { if (n.id === id) return n; }
  return NOTES[0];
}
