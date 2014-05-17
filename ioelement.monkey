Strict

Public

' Preprocessor related:
' Nothing so far.

' Imports:
Import util
Import preprocessor.flags
Import autostream

Import brl.stream
'Import brl.databuffer

' Aliases:
' Nothing so far.

' Interfaces:
Interface InputChildElement
	' Methods:
	Method Load:Bool(S:Stream)
End

Interface OutputChildElement
	' Methods:
	Method Save:Bool(S:Stream)
End

Interface SerializableElement Extends InputChildElement, OutputChildElement
	' Nothing so far.
End

Interface InputElement
	' Constant variable(s):
	' Nothing so far.
	
	' Methods:
	Method ReadInstruction:Int(S:Stream)
	Method ReadEntryData:Int(S:Stream)
	Method SkipEntry:Int(S:Stream)
	
	Method Load:Bool(S:Stream, StreamIsCustom:Bool=False, RestoreOnError:Bool=True)
	
	' Callbacks:
	Method Loading_OnGlobalState:Bool(S:Stream, Instruction:Int, ErrorType:IntObject, State:IntObject, ParentData:BoolObject=Null)
	Method Loading_OnBeginState:Bool(S:Stream, Instruction:Int, ErrorType:IntObject, State:IntObject, ParentData:BoolObject=Null)
	Method Loading_OnHeaderState:Bool(S:Stream, Instruction:Int, ErrorType:IntObject, State:IntObject, ParentData:BoolObject=Null)
	Method Loading_OnBodyState:Bool(S:Stream, Instruction:Int, ErrorType:IntObject, State:IntObject, ParentData:BoolObject=Null)
	Method Loading_OnEndState:Bool(S:Stream, Instruction:Int, ErrorType:IntObject, State:IntObject, ParentData:BoolObject=Null)
End

Interface OutputElement
	' Constant variable(s):
	' Nothing so far.
	
	' Methods:
	Method WriteInstruction:Void(S:Stream, F:Int)
	
	Method WriteEntryPlaceholder:Int(S:Stream)
	Method WriteEntrySize:Int(S:Stream, EntryPosition:Int)
	Method WriteEntryData:Void(S:Stream, Data:Int=0)
	
	Method Save:Bool(S:Stream, StreamIsCustom:Bool=False, RestoreOnError:Bool=True)
	
	' Callbacks:
	' Nothing so far.
End

' Classes:

#Rem
	NOTE:
		Classes based on this class tend to use the associated functionality for manual 'serialization'.
		This is especially useful for configuration, and state-saving. However, please note that this is mostly manual,
		there is no external memory copying involved here, everything must be managed manually.
		The 'IOElement' class gives you a simple framework to work off of, it does not do everything for you.
#End
Class IOElement Implements InputElement, OutputElement
	' Constant variable(s):
	Const Default_CanLoad:Bool = True
	Const Default_CanSave:Bool = True
	
	' File constants:
		
	' General purpose:
	Const ZERO:Int		= 0
	Const ONE:Int		= 1
	
	' File instructions (0-255) (1 through 8 are reserved):
	Const FILE_INSTRUCTION_BEGINFILE:Int			= 1
	Const FILE_INSTRUCTION_ENDFILE:Int				= 2
	Const FILE_INSTRUCTION_BEGINHEADER:Int			= 3
	Const FILE_INSTRUCTION_ENDHEADER:Int			= 4
	Const FILE_INSTRUCTION_BEGINBODY:Int			= 5
	Const FILE_INSTRUCTION_ENDBODY:Int				= 6
	
	' Unused/Reserved file-instructions:
	Const FILE_INSTRUCTION_JUMP:Int					= 7
	Const FILE_INSTRUCTION_ERROR:Int				= 8
	
	' Error codes (I32) (1 through 8 are reserved):
	Const ERROR_NONE:Int					= 0
	Const ERROR_UNKNOWN:Int					= 1
	Const ERROR_NO_BEGINNING:Int			= 2
	Const ERROR_INVALID_INSTRUCTION:Int		= 3
	Const ERROR_END_OF_STREAM:Int			= 4
	Const ERROR_INVALID_HEADER:Int			= 5
	
	' I/O states (I32, but possibly limited by I8 (See file instructions)) (1 through 8 are reserved):
	Const PREVIOUS_STATE:Int	= 0
	Const STATE_NONE:Int		= 1
	Const STATE_BEGIN:Int		= 2
	Const STATE_END:Int			= 3
	Const STATE_HEADER:Int		= 4
	Const STATE_BODY:Int		= 5
	
	' Error / Debug messages:
	#If CONFIG = "debug"
		Const Error_InvalidInstruction:String = "Invalid or unknown file-instruction detected."
		Const Error_NoBeginning:String = "Unable to find format entry-point."
		Const Error_EndOfStream:String = "An unexpected stream-closure has occurred."
		Const Error_Unknown:String = "An unknown error has occurred."
	#End
	
	' Character/String encoding:
	Const CHARACTER_ENCODING_DEFAULT:Int = 0
	Const CHARACTER_ENCODING_UTF8:Int = 1
	Const CHARACTER_ENCODING_ASCII:Int = 2
	
	Const CHARACTER_ENCODING_UTF8_STR:String = "utf8"
	Const CHARACTER_ENCODING_ASCII_STR:String = "ascii"
	Const CHARACTER_ENCODING_DEFAULT_STR:String = CHARACTER_ENCODING_UTF8_STR
	
	' Global variable(s):
	' Nothing so far.
	
	' Functions:
	
	' General:
	Function GetCharacterEncoding:String(Encoding:Int=CHARACTER_ENCODING_DEFAULT)
		Select Encoding
			Case CHARACTER_ENCODING_ASCII
				Return CHARACTER_ENCODING_ASCII_STR
			Case CHARACTER_ENCODING_UTF8
				Return CHARACTER_ENCODING_UTF8_STR
			#Rem
			Case CHARACTER_ENCODING_DEFAULT
				Return CHARACTER_ENCODING_DEFAULT_STR
			#End
		End Select
		
		Return CHARACTER_ENCODING_DEFAULT_STR
	End
	
	Function GetCharacterEncoding:Int(Encoding:String=CHARACTER_ENCODING_DEFAULT_STR)
		Select Encoding.ToLower()
			Case CHARACTER_ENCODING_ASCII_STR
				Return CHARACTER_ENCODING_ASCII
			Case CHARACTER_ENCODING_UTF8_STR
				Return CHARACTER_ENCODING_UTF8
			#Rem
			Default 'Case CHARACTER_ENCODING_DEFAULT_STR
				Return CHARACTER_ENCODING_DEFAULT
			#End
		End Select
		
		Return CHARACTER_ENCODING_DEFAULT
	End
	
	' I/O related:
	Function ReadString:String(S:Stream)
		' Local variable(s):
		Local Encoding:= S.ReadByte()
		Local Length:= S.ReadInt()
		
		' Read the string from the stream, then return it.
		Return S.ReadString(Length, GetCharacterEncoding(Encoding))
	End
	
	Function WriteString:Void(S:Stream, Str:String, Encoding:Int) ' Encoding:Int=CHARACTER_ENCODING_DEFAULT
		WriteString(S, Str, GetCharacterEncoding(Encoding))
		
		Return
	End
	
	Function WriteString:Void(S:Stream, Str:String, Encoding:String=CHARACTER_ENCODING_DEFAULT_STR)
		S.WriteByte(GetCharacterEncoding(Encoding))
		S.WriteInt(Str.Length())
		S.WriteString(Str, Encoding)
		
		Return
	End
	
	Function ReadOptString:String(S:Stream)
		If (ReadBool(S)) Then
			Return ReadString(S)
		Endif
		
		Return ""
	End
	
	Function WriteOptString:Void(S:Stream, Str:String, Toggle:Bool, Encoding:Int)
		WriteOptString(S, Str, Toggle, GetCharacterEncoding(Encoding))
		
		Return
	End
	
	Function WriteOptString:Void(S:Stream, Str:String, Toggle:Bool=True, Encoding:String=CHARACTER_ENCODING_DEFAULT_STR)
		' Make sure we have a string to begin with.
		Toggle = Toggle And (Str.Length() > 0)
		
		WriteBool(S, Toggle)
		
		If (Toggle) Then
			WriteString(S, Str, Encoding)
		Endif
		
		Return
	End
	
	Function ReadBool:Bool(S:Stream)
		Return (S.ReadByte() > ZERO)
	End

	Function WriteBool:Void(S:Stream, Info:Bool)
		If (Info) Then
			S.WriteByte(ONE)
		Else
			S.WriteByte(ZERO)
		Endif
		
		Return
	End
	
	' Used for floating-point values that can be held within smaller sizes:
	Function ReadTinyFloat:Float(S:Stream)
		' Check for errors:
		If (S = Null Or S.Eof()) Then Return 0.0
		
		' Local variable(s):
		Local Output:Float
		
		Output = Float(S.ReadByte()) / 100.0
		
		' Return the processed floating-point value.
		Return Output
	End
	
	Function WriteTinyFloat:Void(S:Stream, Info:Float)
		' Check for errors:
		If (S = Null) Then Return
		
		S.WriteByte(Int(Info * 100.0))
		
		Return
	End
	
	Function ReadOptimizedFloat:Float(S:Stream)
		Return ReadTinyFloat(S)
	End
	
	Function WriteOptimizedFloat:Void(S:Stream, Info:Float)
		WriteTinyFloat(S, Info)
		
		Return
	End
	
	' Constructor(s):
	Method New(CanLoad:Bool=Default_CanLoad, CanSave:Bool=Default_CanSave)
		Self.CanLoad = CanLoad
		Self.CanSave = CanSave
	End
	
	' Methods:
	
	' General:
	' Nothing so far.
	
	' Loading / Saving:
	Method Load:Bool(Path:String)
		If (Not CanLoad) Then Return False
		
		Return Load(OpenAutoStream(Path, "r"), False, False)
	End
	
	Method Load:Bool(S:Stream, StreamIsCustom:Bool=False, RestoreOnError:Bool=True)
		' Check if we're allowed to load.
		If (Not CanLoad) Then Return False
		
		' Make sure we have a stream to work with.
		If (S = Null) Then Return False
		
		' Local variable(s):
		
		' This flag dictates if an instruction will be read on the next cycle.
		Local GetInstruction:Bool = True
		
		' The position in the stream we started at.
		Local StartPosition:Int = S.Position()
		
		Local ErrorType:IntObject = ERROR_NONE
		Local State:IntObject = STATE_NONE
		Local ExitResponse:BoolObject = False
		Local Instruction:Int = ZERO
		
		Local StateStack:= New Stack<Int>()
		
		' Read the file as usual:
		While (Not S.Eof())			
			' Local variable(s):
			Local CurrentState:Int = State
			
			If (GetInstruction) Then
				Instruction = ReadInstruction(S)
			Endif
			
			If (State = PREVIOUS_STATE) Then
				If (Not StateStack.IsEmpty()) Then
					State = StateStack.Pop()
				Else
					State = STATE_END
				Endif
			Else
				If (CurrentState <> State) Then
					StateStack.Push(CurrentState)
				Endif
			Endif
			
			' Reset the read-flag for file-instructions.
			GetInstruction = HandleInstruction(S, Instruction, ErrorType, State, ExitResponse)
			
			If (ExitResponse = True) Then
				' Exit the current loop.
				Exit
			Endif
			
			' If no other errors have occurred, and the stream has
			' ended unexpectedly, set the error code:
			If (ErrorType = ERROR_NONE) Then
				If (S.Eof() And GetInstruction And Instruction <> FILE_INSTRUCTION_ENDFILE) Then
					If (State = STATE_BEGIN) Then
						' If the state never changed, set the error type.
						ErrorType = ERROR_NO_BEGINNING
					Else
						ErrorType = ERROR_END_OF_STREAM
					Endif
				Endif
			Endif
			
			' If an error has occurred, exit the main loop.
			If (ErrorType <> ERROR_NONE) Then Exit
		Wend
		
		' Local variable(s):
		
		' Grab the current position of the stream.
		Local SPosition:Int = S.Position-1
		
		If (ErrorType <> ERROR_NONE) Then
			If (StreamIsCustom And RestoreOnError) Then
				S.Seek(StartPosition)
			Endif
		Endif
		
		If (Not StreamIsCustom) Then
			CloseAutoStream(S)
		Endif
		
		' Check for errors:
		
		' If an error has occurred, do the following:
		#If CONFIG = "debug"
			Local InfoStr:String = "Format-end-position: " + String(SPosition) + " - Start-position: " + String(StartPosition) + " - Offset: " + String(Max(SPosition-StartPosition, 0))
		#End
		
		If (ErrorType <> ERROR_NONE) Then
			' Local variable(s):
			Local ErrorStr:String
			
			#If CONFIG = "debug"
				ErrorStr = ErrorString(ErrorType)
				
				DebugError(ErrorStr + " - " + InfoStr)
			#End
			
			' Tell the user that loading wasn't successful.
			Return False
		Else
			' If there weren't any errors, output debug information.
			#If CONFIG = "debug"
				DebugPrint(InfoStr)
			#End
		Endif
		
		' Return the default response.
		Return True
	End
	
	Method Save:Bool(Path:String)
		' Check for errors:
		
		' Make sure we can save.
		If (Not CanSave) Then Return False
		
		' Call the main implementation, and return its response.
		Return Save(OpenAutoStream(Path, "w"), False, False)
	End
	
	Method Save:Bool(S:Stream, StreamIsCustom:Bool=False, RestoreOnError:Bool=True)
		' Check for errors:
		
		' Make sure we can save.
		If (Not CanSave) Then Return False
		
		' Make sure we have a stream to work with.
		If (S = Null) Then Return False
		
		' Return the default response.
		Return True
	End
	
	' Error handling methods:
	Method ErrorString:String(ErrorType:Int)
		#If CONFIG = "debug"
			Select ErrorType
				Case ERROR_NO_BEGINNING
					Return Error_NoBeginning
					
				Case ERROR_INVALID_INSTRUCTION
					Return Error_InvalidInstruction
				
				Case ERROR_END_OF_STREAM
					Return Error_EndOfStream
										
				Default ' Case ERROR_UNKNOWN
					' Nothing so far.
			End Select
		#End
				
		Return Error_Unknown
	End
	
	' I/O methods:
	Method ReadInstruction:Int(S:Stream)
		Return S.ReadByte()
	End
	
	Method WriteInstruction:Void(S:Stream, F:Int)
		If (F = ZERO) Then Return
		
		S.WriteByte(F)
		
		Return
	End
	
	' This is just a quick wrapper for 'ReadEntryData':
	Method ReadEntry:Int(S:Stream)
		Return ReadEntryData(S)
	End
	
	Method ReadEntryData:Int(S:Stream)
		Return S.ReadInt()
	End
	
	Method SkipEntry:Int(S:Stream)
		' Local variable(s):
		Local EntrySize:= ReadEntryData(S)
		
		' Seek past the entry.
		S.Seek(S.Position+EntrySize)
		
		Return EntrySize
	End
	
	' This is just a quick wrapper for 'WriteEntryData':
	Method WriteEntry:Void(S:Stream, Data:Int=0)
		WriteEntryData(S, Data)
		
		Return
	End
	
	Method WriteEntryData:Void(S:Stream, Data:Int=0)
		S.WriteInt(Data)
		
		Return
	End
	
	Method WriteEntryPlaceholder:Int(S:Stream)		
		' Local variable(s):
		Local Position:= S.Position
		
		WriteEntryData(S)
		
		Return Position
	End
	
	Method WriteEntrySize:Int(S:Stream, EntryPosition:Int)
		' Local variable(s):
		Local CurrentPosition:Int = S.Position
		Local EntrySize:Int = CurrentPosition - EntryPosition
		
		' Seek back to the entry-position.
		S.Seek(EntryPosition)
		
		' Write a new entry-size based on the current stream-position.
		WriteEntryData(S, EntrySize)
		
		' Seek back to the position we started at.
		S.Seek(CurrentPosition)
		
		Return EntrySize
	End
	
	Method HandleInstruction:Bool(S:Stream, Instruction:Int, ErrorType:IntObject, State:IntObject, ExitResponse:BoolObject=Null, ParentData:BoolObject=Null)
		' Local variable(s):
		Local GetInstruction:Bool = True
		
		If (ParentData = Null) Then
			ParentData = False
		Endif
		
		If (ExitResponse = Null) Then
			ExitResponse = False
		Endif
		
		If (Not ParentData) Then
			' Set the default parent response.
			ParentData.value = True
			
			Select State
				' The 'none' state is treated slightly differently from other states;
				' this is because the 'begin-file' instruction is actually
				' a required format-note, and not a full instruction.
				Case STATE_NONE
					GetInstruction = Loading_OnGlobalState(S, Instruction, ErrorType, State)
								
				' This should be treated as an intermediate point for other states:
				Case STATE_BEGIN
					GetInstruction = Loading_OnBeginState(S, Instruction, ErrorType, State)
				
				Case STATE_HEADER
					GetInstruction = Loading_OnHeaderState(S, Instruction, ErrorType, State)
				
				Case STATE_BODY
					GetInstruction = Loading_OnBodyState(S, Instruction, ErrorType, State)
								
				Case STATE_END
					GetInstruction = Loading_OnEndState(S, Instruction, ErrorType, State)
					ExitResponse = True
				
				Default
					ParentData.value = False
			End Select
		Endif
		
		Return GetInstruction
	End
	
	' Callbacks (Implemented):
	Method Loading_OnGlobalState:Bool(S:Stream, Instruction:Int, ErrorType:IntObject, State:IntObject, ParentData:BoolObject=Null)
		' Local variable(s):
		Local GetInstruction:Bool = True
		
		If (ParentData = Null) Then
			ParentData = False
		Endif
		
		If (Not ParentData) Then
			' Set the default parent response.
			ParentData.value = True
			
			' ATTENTION: DO NOT USE THE ARGUMENTS DIRECTLY WHEN SETTING VALUES,
			' USE THEIR 'value' FIELDS; THAT BEING SAID, READING CAN BE DONE NORMALLY.
			Select Instruction
				Case ZERO
					' Nothing for now.
				Case FILE_INSTRUCTION_BEGINFILE
					State.value = STATE_BEGIN
				Default
					ParentData.value = False
					'ErrorType.value = ERROR_INVALID_INSTRUCTION
			End Select
		Endif
		
		Return GetInstruction
	End
	
	Method Loading_OnBeginState:Bool(S:Stream, Instruction:Int, ErrorType:IntObject, State:IntObject, ParentData:BoolObject=Null)
		' Local variable(s):
		Local GetInstruction:Bool = True
		
		If (ParentData = Null) Then
			ParentData = False
		Endif
		
		If (Not ParentData) Then
			' Set the default parent-response.
			ParentData.value = True
			
			Select Instruction
				Case ZERO
					' Nothing for now.
				Case FILE_INSTRUCTION_BEGINHEADER
					State.value = STATE_HEADER
					GetInstruction = False
				Case FILE_INSTRUCTION_BEGINBODY
					State.value = STATE_BODY
					GetInstruction = False
				Case FILE_INSTRUCTION_ENDFILE
					State.value = STATE_END
					GetInstruction = False
				Default
					ParentData.value = False
					'ErrorType.value = ERROR_INVALID_INSTRUCTION
			End Select
		Endif
		
		Return GetInstruction
	End
	
	Method Loading_OnHeaderState:Bool(S:Stream, Instruction:Int, ErrorType:IntObject, State:IntObject, ParentData:BoolObject=Null)
		' Local variable(s):
		Local GetInstruction:Bool = True
		
		If (ParentData = Null) Then
			ParentData = False
		Endif
		
		If (Not ParentData) Then
			' Set the default parent response.
			ParentData.value = True
			
			Select Instruction
				Case ZERO
					' Nothing for now.
				Case FILE_INSTRUCTION_ENDHEADER
					State.value = PREVIOUS_STATE ' STATE_BEGIN
				Default
					ParentData.value = False
					'ErrorType.value = ERROR_INVALID_INSTRUCTION
			End Select
		Endif
		
		Return GetInstruction
	End
	
	Method Loading_OnBodyState:Bool(S:Stream, Instruction:Int, ErrorType:IntObject, State:IntObject, ParentData:BoolObject=Null)
		' Local variable(s):
		Local GetInstruction:Bool = True
		
		If (ParentData = Null) Then
			ParentData = False
		Endif
		
		If (Not ParentData) Then
			' Set the default parent response.
			ParentData.value = True
			
			Select Instruction
				Case ZERO
					' Nothing so far.
									
				Case FILE_INSTRUCTION_ENDBODY
					State.value = PREVIOUS_STATE ' STATE_BEGIN
				
				Default
					ParentData.value = False
					'ErrorType.value = ERROR_INVALID_INSTRUCTION
			End Select
		Endif
		
		Return GetInstruction
	End
	
	Method Loading_OnEndState:Bool(S:Stream, Instruction:Int, ErrorType:IntObject, State:IntObject, ParentData:BoolObject=Null)
		' Local variable(s):
		Local GetInstruction:Bool = True
		
		If (ErrorType = ERROR_NONE) Then
			If (State <> STATE_END) Then
				ErrorType.value = ERROR_INVALID_INSTRUCTION
			Endif
		Endif
		
		Return GetInstruction
	End
	
	' Callbacks (Abstract):
	' Nothing so far.
	
	' Fields:
	
	' Flags:
	Field CanLoad:Bool
	Field CanSave:Bool
End