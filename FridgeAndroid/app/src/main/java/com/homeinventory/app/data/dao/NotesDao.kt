package com.homeinventory.app.data.dao

import androidx.room.*
import com.homeinventory.app.model.NoteEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface NotesDao {
    
    @Query("SELECT * FROM notes ORDER BY lastModified DESC")
    fun getAllNotes(): Flow<List<NoteEntity>>
    
    @Query("SELECT * FROM notes WHERE id = :id")
    suspend fun getNoteById(id: String): NoteEntity?
    
    @Query("SELECT COUNT(*) FROM notes")
    suspend fun getNotesCount(): Int
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertNote(note: NoteEntity)
    
    @Update
    suspend fun updateNote(note: NoteEntity)
    
    @Delete
    suspend fun deleteNote(note: NoteEntity)
    
    @Query("DELETE FROM notes")
    suspend fun deleteAllNotes()
    
    @Query("UPDATE notes SET title = :title, content = :content, lastModified = :lastModified WHERE id = :id")
    suspend fun updateNoteContent(id: String, title: String, content: String, lastModified: Long)
}