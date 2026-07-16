// Public UI-shell note model used by the deterministic fresh-install fixture.

export enum NoteColor {
  Default = 'Default',
  Red = 'Red',
  Orange = 'Orange',
  Yellow = 'Yellow',
  Green = 'Green',
  Teal = 'Teal',
  Cyan = 'Cyan',
  Blue = 'Blue',
  Purple = 'Purple',
  Pink = 'Pink',
  Brown = 'Brown',
  Gray = 'Gray'
}

export interface Task {
  content: string;
  done: boolean;
}

export interface Note {
  id: number;
  title: string;
  content: string;        // plain preview text
  isList: boolean;
  tasks: Task[];
  color: NoteColor;
  notebook: string | null;
  tags: string[];
  isPinned: boolean;
  hasReminder: boolean;
  isMarkdown: boolean;
  createdText: string;
  modifiedText: string;
  archived: boolean;
  deleted: boolean;
  hidden?: boolean;       // hidden flag (excluded from lists unless showHidden)
  localOnly?: boolean;    // do-not-sync flag (observable; no network effect)
  swatched?: boolean;     // screen-always-on flag (observable; no platform effect)
}

export interface Notebook {
  id: number;
  name: string;
}

export interface TagItem {
  id: number;
  name: string;
}

// Stable light-theme colors for the public note fixture.
export function noteColorHex(c: NoteColor): string {
  switch (c) {
    case NoteColor.Red: return '#EF9A9A';
    case NoteColor.Orange: return '#F29F75';
    case NoteColor.Yellow: return '#FFF59D';
    case NoteColor.Green: return '#C5E1A5';
    case NoteColor.Teal: return '#B4DED3';
    case NoteColor.Cyan: return '#A5DCEB';
    case NoteColor.Blue: return '#AACCF5';
    case NoteColor.Purple: return '#C8AED2';
    case NoteColor.Pink: return '#FAAFC8';
    case NoteColor.Brown: return '#D2C3B4';
    case NoteColor.Gray: return '#C8C8D2';
    default: return '#FFFFFF';
  }
}
