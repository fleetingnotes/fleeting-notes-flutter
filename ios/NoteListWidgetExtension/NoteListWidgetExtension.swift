//
//  NoteListWidgetExtension.swift
//  NoteListWidgetExtension
//
//  Created by Matthew Wong on 2022-11-15.
//

import WidgetKit
import SwiftUI

private let widgetGroupId = "group.com.fleetingnotes"

public extension Color {
    #if os(macOS)
    static let background = Color(NSColor.windowBackgroundColor)
    static let secondaryBackground = Color(NSColor.underPageBackgroundColor)
    static let tertiaryBackground = Color(NSColor.controlBackgroundColor)
    #else
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    #endif
}

struct Note: Decodable, Identifiable {
    let id: String
    let title: String
    let content: String
    let source: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NotesListEntry {
        NotesListEntry(date: Date(), notes: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (NotesListEntry) -> ()) {
        let decoder = JSONDecoder()
        let data = UserDefaults.init(suiteName:widgetGroupId)
        let notesData = (data?.string(forKey: "notes"))!.data(using: .utf8)!
        var notesList: [Note] = []
        do {
            notesList = try decoder.decode([Note].self, from: notesData)
            print(notesList)
        } catch {
            print(error)
        }
        
        let entry = NotesListEntry(date: Date(), notes: notesList)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        getSnapshot(in: context) { (entry) in
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct NotesListEntry: TimelineEntry {
    let date: Date
    let notes: [Note]
}

struct NoteListWidgetExtensionEntryView : View {
    var entry: Provider.Entry
    let data = UserDefaults.init(suiteName:widgetGroupId)

    var body: some View {
        Link(destination: URL(string: "fleetingNotesWidget://home&homeWidget")!) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading) {
                    ForEach(Array(entry.notes.prefix(5))) { note in
                        Link(destination: URL(string: "fleetingNotesWidget://note?id=\(note.id)&homeWidget")!) {
                            VStack(alignment: .leading) {
                                // if title isn't empty
                                if (!note.title.isEmpty) {
                                    VStack(alignment: .leading) {
                                        Text(note.title)
                                            .font(.headline)
                                            .lineLimit(1)
                                        Text(note.content)
                                            .font(.subheadline)
                                    }
                                    .padding(3)
                                    
                                } else {
                                    Text(note.content)
                                        .font(.subheadline)
                                        .padding(3)
                                }
                            }
                            // small / med: 45 height, large: 65 height
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 45, maxHeight: 70, alignment: .topLeading)
                            .background(Color.secondaryBackground)
                            .cornerRadius(10)
                        }
                    }
                    
                }
                .padding(5)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(UIColor.systemBackground))
                Link(destination: URL(string: "fleetingNotesWidget://note?homeWidget")!) {
                    Button(action: {
                        // action here
                    }) {
                        Image(systemName: "plus")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 15, height: 15)
                            .padding(15)
                    }
                    .background(Color.accentColor)
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
                    .padding(5)
                    .frame(alignment: .bottomTrailing)
                }
                
            }
        }
    }
}

@main
struct NoteListWidgetExtension: Widget {
    let kind: String = "NoteListWidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NoteListWidgetExtensionEntryView(entry: entry)
        }
        .supportedFamilies([.systemMedium, .systemLarge])
        .configurationDisplayName("Note List")
        .description("View your latest notes")
    }
}

struct NoteListWidgetExtension_Previews: PreviewProvider {
    static var previews: some View {
        NoteListWidgetExtensionEntryView(entry: NotesListEntry(date: Date(), notes: [Note(id: "", title: "note title", content: "This is some content.\nCool beans.", source: "")]))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
