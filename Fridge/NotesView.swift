import SwiftUI

struct NotesView: View {
    @EnvironmentObject var notesManager: NotesManager
    @State private var showingNoteEditor = false
    @State private var showingNoteViewer = false
    @State private var selectedNote: Note?
    @State private var showingLimitAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if notesManager.notes.isEmpty {
                    EmptyNotesView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(Array(notesManager.notes.enumerated()), id: \.element.id) { index, note in
                                NoteCardView(
                                    note: note,
                                    noteNumber: index + 1,
                                    onEdit: {
                                        selectedNote = note
                                        showingNoteEditor = true
                                    },
                                    onView: {
                                        selectedNote = note
                                        showingNoteViewer = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if notesManager.canAddNote {
                            notesManager.addNote()
                            if let newNote = notesManager.notes.first {
                                selectedNote = newNote
                                showingNoteEditor = true
                            }
                        } else {
                            showingLimitAlert = true
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNoteEditor) {
            if let note = selectedNote {
                NoteEditorView(note: note)
            }
        }
        .sheet(isPresented: $showingNoteViewer) {
            if let note = selectedNote {
                NoteViewerView(note: note, onEdit: {
                    showingNoteViewer = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showingNoteEditor = true
                    }
                })
            }
        }
        .alert("Note Limit Reached", isPresented: $showingLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can only have up to 6 notes. Please delete one and try again.")
        }
    }
    
}

struct EmptyNotesView: View {
    @EnvironmentObject var notesManager: NotesManager
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "note.text")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Notes Yet")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Tap the + button to create your first quick note. You can have up to 6 notes.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                if notesManager.canAddNote {
                    notesManager.addNote()
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create First Note")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(notesManager.canAddNote ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(!notesManager.canAddNote)
        }
        .padding()
    }
}

struct NoteCardView: View {
    @ObservedObject var note: Note
    @EnvironmentObject var notesManager: NotesManager
    let noteNumber: Int
    let onEdit: () -> Void
    let onView: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with number and date
            HStack {
                Text("\(noteNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Color.blue))
                
                Spacer()
                
                Text(formatDate(note.lastModified))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Title
            Text(note.title.isEmpty ? "Untitled Note" : note.title)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Content preview
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("No content")
                    .font(.body)
                    .foregroundColor(.gray)
                    .italic()
            }
            
            Spacer()
            
            // Action buttons
            HStack {
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .frame(minHeight: 140)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onView()
        }
        .alert("Delete Note", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                notesManager.deleteNote(note)
            }
        } message: {
            Text("Are you sure you want to delete this note?")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDate(date, inSameDayAs: Date()) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "E"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

struct NoteEditorView: View {
    @ObservedObject var note: Note
    @EnvironmentObject var notesManager: NotesManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Title Field
                TextField("Note Title", text: $title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color(.systemGray6))
                
                // Content Field
                TextEditor(text: $content)
                    .padding()
                    .background(Color(.systemBackground))
            }
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: HStack {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    
                    Button("Save") {
                        notesManager.updateNote(note, title: title, content: content)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            )
        }
        .onAppear {
            title = note.title
            content = note.content
        }
        .alert("Delete Note", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                notesManager.deleteNote(note)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
    }
}

struct NoteViewerView: View {
    @ObservedObject var note: Note
    @EnvironmentObject var notesManager: NotesManager
    @Environment(\.presentationMode) var presentationMode
    let onEdit: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(note.title.isEmpty ? "Untitled Note" : note.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        if note.content.isEmpty {
                            Text("No content")
                                .font(.body)
                                .foregroundColor(.gray)
                                .italic()
                        } else {
                            Text(note.content)
                                .font(.body)
                        }
                    }
                    
                    Divider()
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Modified")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(formatDate(note.lastModified))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("View Note")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: HStack {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    
                    Button("Edit") {
                        onEdit()
                    }
                    .fontWeight(.semibold)
                }
            )
        }
        .alert("Delete Note", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                notesManager.deleteNote(note)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NotesView()
        .environmentObject(NotesManager())
}