package com.homeinventory.app.repository

import com.homeinventory.app.data.dao.NotesDao
import com.homeinventory.app.model.Note
import com.homeinventory.app.model.NoteEntity
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NotesRepository @Inject constructor(
    private val notesDao: NotesDao
) {
    
    fun getAllNotes(): Flow<List<Note>> {
        return notesDao.getAllNotes().map { entities ->
            entities.map { Note.fromEntity(it) }
        }
    }
    
    suspend fun getNoteById(id: String): Note? {
        return notesDao.getNoteById(id)?.let { Note.fromEntity(it) }
    }
    
    suspend fun getNotesCount(): Int {
        return notesDao.getNotesCount()
    }
    
    suspend fun canAddNote(): Boolean {
        return getNotesCount() < 6
    }
    
    suspend fun addNote(): Note? {
        if (!canAddNote()) return null
        
        val noteEntity = NoteEntity(
            title = "",
            content = "",
            createdDate = Date(),
            lastModified = Date()
        )
        
        notesDao.insertNote(noteEntity)
        return Note.fromEntity(noteEntity)
    }
    
    suspend fun updateNote(note: Note) {
        notesDao.updateNote(note.toEntity())
    }
    
    suspend fun updateNoteContent(id: String, title: String, content: String) {
        notesDao.updateNoteContent(id, title, content, Date().time)
    }
    
    suspend fun deleteNote(note: Note) {
        notesDao.deleteNote(note.toEntity())
    }
    
    suspend fun deleteAllNotes() {
        notesDao.deleteAllNotes()
    }
}