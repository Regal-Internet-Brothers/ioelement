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
		
		The base IOElement class (Unstructured) requires several instruction to be implemented via call-back overloads.
		For a more structured experience, look at the 'StructuredIOElement' class, and/or the 'AsyncIOElement' class.
#End
Class IOElement Implements InputElement, OutputElement
	' Constant variable(s):
	
	' Defaults:
	
	' Booleans / Flags:
	Const Default_CanLoad:Bool = True
	Const Default_CanSave:Bool = True
	
	' File constants:
		
	' General purpose:
	Const ZERO:Int		= 0
	Const ONE:Int		= 1
	
	' File instructions (0-255) (1 through 'CUSTOM_INSTRUCTION_LOCATION-1' are reserved):
	Const FILE_INSTRUCTION_BEGINFILE:Int			= 1
	Const FILE_INSTRUCTION_ENDFILE:Int				= 2
	Const FILE_INSTRUCTION_BEGINHEADER:Int			= 3
	Const FILE_INSTRUCTION_ENDHEADER:Int			= 4
	Const FILE_INSTRUCTION_BEGINBODY:Int			= 5
	Const FILE_INSTRUCTION_ENDBODY:Int				= 6
	
	' Unused/Reserved file-instructions:
	Const FILE_INSTRUCTION_JUMP:Int					= 7
	Const FILE_INSTRUCTION_ERROR:Int				= 8
	
	#Rem
		This is the lowest possible instruction/operation code position possible for inheriting classes.
		Each 'IOElement' class has the ability to redefine this.
		It's best to just offset based on this value (Defined by your super-class).
	#End
	
	Const CUSTOM_INSTRUCTION_LOCATION:Int = 9
	
	' Error codes (I32) (1 through 'CUSTOM_ERROR_LOCATION-1' are reserved):
	Const ERROR_NONE:Int							= 0
	Const ERROR_UNKNOWN:Int							= 1
	Const ERROR_NO_BEGINNING:Int					= 2
	Const ERROR_INVALID_INSTRUCTION:Int				= 3
	Const ERROR_END_OF_STREAM:Int					= 4
	Const ERROR_INVALID_HEADER:Int					= 5
	Const ERROR_UNSUPPORTED_VERSION:Int				= 6
	Const ERROR_INVALID_INITIALIZATION_PATH:Int		= 7
	
	#Rem
		This is the lowest possible error-code position for inheriting classes.
		Each 'IOElement' class has the ability to redefine this if neccessary.
		It's best to just offset based on this value (Defined by your super-class).
	#End
	
	Const CUSTOM_ERROR_LOCATION:Int = 9
	
	' I/O states (I32, but possibly limited by I8 (See file instructions)) (1 through 'CUSTOM_STATE_LOCATION-1' are reserved):
	Const PREVIOUS_STATE:Int	= 0
	Const STATE_NONE:Int		= 1
	Const STATE_BEGIN:Int		= 2
	Const STATE_END:Int			= 3
	Const STATE_HEADER:Int		= 4
	Const STATE_BODY:Int		= 5
	
	#Rem
		This is the lowest possible state identifier position possible for inheriting classes.
		Each 'IOElement' class has the ability to redefine this.
		It's best to just offset based on this value (Defined by your super-class).
	#End
	
	Const CUSTOM_STATE_LOCATION:Int = 9
	
	' Error / Debug messages:
	#If CONFIG = "debug"
		Const Error_InvalidInstruction:String = "Invalid or unknown file-instruction detected."
		Const Error_NoBeginning:String = "Unable to find format entry-point."
		Const Error_EndOfStream:String = "An unexpected stream-closure has occurred."
		Const Error_UnsupportedVersion:String = "The detected file-version is incompatible."
		Const Error_InvalidInitializationPath:String = "Invalid initialization path."
	#End
	
	Const Error_Unknown:String = "An unknown error has occurred."
	
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
		' Check for errors:
		If (Not CanLoad) Then Return False
		
		Return Load(OpenAutoStream(Path, "r"), False, False)
	End
	
	' The 'StreamIsCustom' argument specifies if the stream should be closed when finished.
	' If the stream is custom, it will not close. However, if 'RestoreOnError' is enabled,
	' it will at least seek back if an error occurs while loading.
	
	' Multi-pass loading is up to the inheriting implementation,
	' to tell if the loading process was completed, check the 'Loading' flag/field.
	Method Load:Bool(S:Stream, StreamIsCustom:Bool=True, RestoreOnError:Bool=True)
		' Check if we're allowed to load.
		If (Not CanLoad) Then Return False
		
		' Make sure we have a stream to work with.
		If (S = Null Or S.Eof()) Then Return False
		
		' This is here to make the 'AsyncIOElement' class a bit easier to make:
		S = UseStream(S, StreamIsCustom, RestoreOnError, "r")
		
		' Make sure we could use the stream.
		If (S = Null) Then Return False
		
		' Local variable(s):
		
		' This flag dictates if an instruction will be read on the next cycle.
		Local GetInstruction:Bool = True
		
		' This flag indicates if the loading process was paused.
		Local Paused:BoolObject = Null
		
		' If we're able to pause, generate a new object:
		If (CanPause) Then
			Paused = False
		Endif
		
		' The position in the stream we started at.
		Local StartPosition:Int = GetStartPosition(S)
		
		Local ErrorType:IntObject = GetErrorObject()
		Local State:IntObject = GetStateObject()
		Local ExitResponse:BoolObject = False
		Local Instruction:Int = ZERO
		
		Local StateStack:= GetStateStack()
		
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
			GetInstruction = HandleInstruction(S, Instruction, ErrorType, State, ExitResponse, Paused)
			
			' Check if the exit-response object is set to true:
			If (ExitResponse = True Or Paused <> Null And Paused = True) Then
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
		
		' Grab the current position of the stream.
		Local SPosition:Int = S.Position-1
		
		Local PauseResponse:Bool = BoolObjectIsTrue(Paused)
		
		If (StreamIsCustom) Then
			If (ErrorType <> ERROR_NONE) Then
				If (RestoreOnError) Then
					S.Seek(StartPosition)
					
					If (Paused <> Null) Then
						Paused = False
					Endif
				Endif
			Endif
		Else
			If (Not PauseResponse) Then
				FinishLoading(S, StreamIsCustom)
			Endif
		Endif
		
		If (Not PauseResponse) Then
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
		Endif
		
		' Return the default response.
		Return True
	End
	
	Method Load:Bool()
		' Always return false. (This class does not support multi-pass loading)
		Return False
	End
	
	Method Save:Bool(Path:String)
		' Check for errors:
		
		' Make sure we can save.
		If (Not CanSave) Then Return False
		
		' Call the main implementation, and return its response.
		Return Save(OpenAutoStream(Path, "w"), False, False)
	End
	
	' Calling up to this implementation of this command is mostly just required for multi-pass saving,
	' but technically it's possible to work around this:
	Method Save:Bool(S:Stream, StreamIsCustom:Bool=False, RestoreOnError:Bool=True)
		' Check for errors:
		
		' Make sure we can save:
		If (Not CanSave) Then Return False
		
		' Make sure we have a stream to work with.
		If (S = Null) Then Return False
		
		S = UseStream(S, StreamIsCustom, RestoreOnError, "w")
		
		' Check if the stream is still usable.
		If (S = Null) Then Return False
		
		' Return the default response.
		Return True
	End
	
	Method Save:Bool()
		' Always return false. (See the argumentless overload for 'Load')
		Return False
	End
	
	Method FinishLoading:Void(S:Stream, StreamIsCustom:Bool=False)
		CloseAutoStream(S, StreamIsCustom)
		
		Return
	End
	
	Method FinishSaving:Void(S:Stream, StreamIsCustom:Bool=False)
		FinishLoading(S, StreamIsCustom)
		
		Return
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
				
				Case ERROR_UNSUPPORTED_VERSION
					Return Error_UnsupportedVersion
				
				Case ERROR_INVALID_INITIALIZATION_PATH
					Return Error_InvalidInitializationPath
				
				Default ' Case ERROR_UNKNOWN
					' Nothing so far.
			End Select
		#End
				
		Return Error_Unknown
	End
	
	' I/O methods:
	Method UseStream:Stream(S:Stream, StreamIsCustom:Bool, RestoreOnError:Bool, Mode:String="r")
		Return S
	End
	
	Method GetStartPosition:Int(S:Stream)
		Return S.Position
	End
	
	Method GetStateObject:IntObject()
		Return STATE_NONE ' New IntObject(STATE_NONE)
	End
	
	Method GetStateStack:Stack<Int>()
		Return New Stack<Int>()
	End
	
	Method GetErrorObject:IntObject()
		Return ERROR_NONE ' New IntObject(ERROR_NONE)
	End
	
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
	
	' Reimplementing either of these commands is completely optional. However, this overload in particular should only be implemented if you want multi-pass loading.
	Method HandleInstruction:Bool(S:Stream, Instruction:Int, ErrorType:IntObject, State:IntObject, ExitResponse:BoolObject, ParentData:BoolObject, Pause:BoolObject)
		' Call the main implementation.
		Return HandleInstruction(S, Instruction, ErrorType, State, ExitResponse, ParentData)
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
					GetInstruction = Loading_OnGlobalState(S, Instruction, ErrorType, State, ParentData)
				
				' This should be treated as an intermediate point for other states:
				Case STATE_BEGIN
					GetInstruction = Loading_OnBeginState(S, Instruction, ErrorType, State, ParentData)
				
				Case STATE_HEADER
					GetInstruction = Loading_OnHeaderState(S, Instruction, ErrorType, State, ParentData)
				
				Case STATE_BODY
					GetInstruction = Loading_OnBodyState(S, Instruction, ErrorType, State, ParentData)
				
				Case STATE_END
					GetInstruction = Loading_OnEndState(S, Instruction, ErrorType, State, ParentData)
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
	
	' Other:
	Method BoolObjectIsTrue:Bool(BO:BoolObject)
		If (BO = Null) Then Return False
		
		Return BO
	End
	
	' Properties:
	Method CanPause:Bool() Property
		Return False
	End
	
	' Fields:
	
	' Booleans / Flags:
	Field CanLoad:Bool
	Field CanSave:Bool
End

Class StructuredIOElement Extends IOElement Abstract
	' Constant variable(s):
	' Nothing so far.
	
	' Constructor(s):
	Method New(CanLoad:Bool=Default_CanLoad, CanSave:Bool=Default_CanSave)
		' Call the super-class's constructor.
		Super.New(CanLoad, CanSave)
		
		' Nothing else so far.
	End
	
	' Methods:
	
	' Call-backs:
	
	' Custom call-backs:
	Method Loading_OnBeginBody:Bool(S:Stream, ErrorType:IntObject, State:IntObject)
		' Implement this as you please.
		
		' Return the default response.
		Return True
	End
	
	Method Loading_OnBeginHeader:Bool(S:Stream, ErrorType:IntObject, State:IntObject)
		' Implement this as you please.
		
		' Return the default response.
		Return True
	End
	
	' Main call-backs:
	Method Loading_OnHeaderState:Bool(S:Stream, Instruction:Int, ErrorType:IntObject, State:IntObject, ParentData:BoolObject=Null)
		' Create the parent-data object.
		If (ParentData = Null) Then
			ParentData = False ' New BoolObject()
		Endif
		
		' Local variable(s):
		Local GetInstruction:Bool = Super.Loading_OnHeaderState(S, Instruction, ErrorType, State, ParentData)
		
		If (Not ParentData) Then
			ParentData.value = True
			
			Select Instruction
				Case ZERO
					' Nothing for now.
				
				Case FILE_INSTRUCTION_BEGINHEADER
					If (Not Loading_OnBeginHeader(S, ErrorType, State)) Then
						ErrorType.value = ERROR_INVALID_HEADER
						
						Return False
					Endif
					
				Default
					ParentData.value = False
					'ErrorType.value = ERROR_INVALID_INSTRUCTION
			End Select
		Endif
		
		Return GetInstruction
	End
	
	Method Loading_OnBodyState:Bool(S:Stream, Instruction:Int, ErrorType:IntObject, State:IntObject, ParentData:BoolObject=Null)
		' Create the parent-data object.
		If (ParentData = Null) Then
			ParentData = False ' New BoolObject()
		Endif
		
		' Local variable(s):
		Local GetInstruction:Bool = Super.Loading_OnBodyState(S, Instruction, ErrorType, State, ParentData)
		
		If (Not ParentData) Then
			ParentData.value = True
			
			Select Instruction
				Case FILE_INSTRUCTION_BEGINBODY
					GetInstruction = Loading_OnBeginBody(S, ErrorType, State)
				Default
					ParentData.value = False
					'ErrorType.value = ERROR_INVALID_INSTRUCTION
			End Select
		Endif
		
		Return GetInstruction
	End
End

' The term asynchronous (In this context) is meant to be in regards to multi-pass
' loading and/or saving, not multi-threaded designs (As of yet).

' The 'IOElementType' parameter for this class can be any valid 'I/O element' class.
' Generally speaking, this will be either 'IOElement', or 'StructuredIOElement'.
' That being said, as long as it follows the designs and ideals of those classes, any class may be used.
' Ideally, you'll want the specified class to extend the 'IOElement' class, but for now this is not a requirement.
Class AyncIOElement<IOElementType> Extends IOElementType Abstract
	' Constant variable(s):
	
	' Defaults:
	
	' Booleans / Flags:
	Const Default_IO_StreamIsCustom:Bool = False
	Const Default_IO_RestoreOnError:Bool = True
	
	' Constructor(s):
	Method New(CanLoad:Bool=Default_CanLoad, CanSave:Bool=Default_CanSave)
		' Call the super-class's implementation.
		Super.New(CanLoad, CanSave)
		
		' Apply the defaults for the stream management flags:
		Self.IO_StreamIsCustom = Default_IO_StreamIsCustom
		Self.IO_RestoreOnError = Default_IO_RestoreOnError
	End
	
	' Destructor(s):
	Method FlushIO:Void()
		IO_Stream = Null
		IO_StartPosition = -1
		
		If (IO_State <> Null) Then
			IO_State.value = STATE_NONE ' Null
		Endif
		
		If (IO_StateStack <> Null) Then
			IO_StateStack.Clear()
		Endif
		
		Return
	End
	
	' Methods (Public):
	
	' Loading / Saving:
	Method Load:Bool(Path:String)
		' Check for errors:
		If (Saving Or Loading) Then
			Return False
		Endif
		
		' Call the main implementation, and return its response.
		Return Super.Load(Path)
	End
	
	Method Load:Bool(S:Stream, StreamIsCustom:Bool=True, RestoreOnError:Bool=True)
		Return Super.Load(S, StreamIsCustom, RestoreOnError)
	End
	
	Method Load:Bool()
		' Check for errors:
		If (IO_Stream = Null Or IO_Stream.Eof()) Then Return False
		If (Saving) Then Return False
		'If (Not Loading) Then Return False
		
		' Just for the sake of keeping things simple, set the loading-flag to false.
		Loading = False
		
		' Call the main implementation, and return its response.
		Return Load(IO_Stream, IO_StreamIsCustom, IO_RestoreOnError)
	End
	
	Method Save:Bool(S:Stream, StreamIsCustom:Bool=False, RestoreOnError:Bool=True)
		' Check for errors:
		If (Loading Or Saving) Then
			Return False
		Endif
		
		' Call the main implementation, and return its response.
		Return Super.Save(S, StreamIsCustom, RestoreOnError)
	End
	
	Method Save:Bool(Path:String)
		' Check for errors:
		If (Saving Or Loading) Then
			Return False
		Endif
		
		' Call the main implementation, and return its response..
		Return Super.Save(Path)
	End
	
	Method Save:Bool()
		' Check for errors:
		If (IO_Stream = Null) Then Return False
		If (Loading) Then Return False
		'If (Not Saving) Then Return False
		
		' Just for the sake of keeping things simple, set the saving-flag to false.
		Saving = False
		
		' Call the main implementation, and return its response.
		Return Save(IO_Stream, IO_StreamIsCustom, IO_RestoreOnError)
	End
	
	' The value returned from this command indicates its effect.
	' If the return value is true, more advancement must be done.
	' If the return value is false, no more advancement can be done.
	' This could also mean that some form of error has occurred, to check for errors, check the 'ERROR' field.
	Method Advance:Bool()
		' Local variable(s):
		Local Response:Bool = False
		
		If (Loading) Then
			Response = Load()
		Elseif (Saving) Then
			Response = Save()
		Endif
		
		If (Response) Then
			If (Loading Or Saving) Then
				Response = True
			Else
				Response = False
			Endif
		Endif
		
		' Return the calculated response.
		Return Response
	End
	
	' I/O methods:
	Method UseStream:Stream(S:Stream, StreamIsCustom:Bool, RestoreOnError:Bool, Mode:String="r")
		If (Mode = "r") Then
			If (Self.Saving) Then
				CloseAutoStream(S, StreamIsCustom)
				
				Return Null
			Endif
			
			' Set the loading-flag to true.
			Self.Loading = True
		Elseif (Mode = "w") Then
			If (Self.Loading) Then
				CloseAutoStream(S, StreamIsCustom)
				
				Return Null
			Endif
			
			' Set the saving-flag to true.
			Self.Saving = True
		Else
			Return Null
		Endif
		
		' Set the stream options:
		Self.IO_StreamIsCustom = StreamIsCustom
		Self.IO_RestoreOnError = RestoreOnError
		
		' Set the internal stream to the stream specified.
		Self.IO_Stream = S
		
		' Set the error-object back to the default:
		If (Self.IO_ErrorType <> Null) Then
			Self.IO_ErrorType.value = ERROR_NONE ' Null
		Endif
		
		Return IO_Stream
	End
	
	Method GetStartPosition:Int(S:Stream)
		If (IO_StartPosition = -1) Then
			IO_StartPosition = Super.GetStartPosition(S) ' S.Position()
		Endif
		
		Return IO_StartPosition
	End
	
	Method GetStateObject:IntObject()
		If (IO_State = Null) Then
			IO_State = Super.GetStateObject() ' STATE_NONE ' New IntObject(STATE_NONE)
		Endif
		
		Return IO_State
	End
	
	Method GetStateStack:Stack<Int>()
		If (IO_StateStack = Null) Then
			IO_StateStack = Super.GetStateStack() ' New Stack<Int>()
		Endif
		
		Return IO_StateStack
	End
	
	Method GetErrorObject:IntObject()
		If (IO_ErrorType = Null) Then
			IO_ErrorType = Super.GetErrorObject()
		Endif
		
		Return IO_ErrorType
	End
	
	' Methods (Private):
	Private
	
	' Saving / Loading:
	Method FinishLoading:Void(S:Stream, StreamIsCustom:Bool=False)
		' Local variable(s):
		Local IsOurStream:Bool = (S = IO_Stream)
		
		If (IsOurStream) Then
			Loading = False
		Endif
		
		Super.FinishLoading(S, StreamIsCustom)
		
		'CloseAutoStream(S, StreamIsCustom)
		
		'IO_StreamIsCustom = Default_IO_StreamIsCustom
		'IO_RestoreOnError = Default_IO_RestoreOnError
		
		If (IsOurStream) Then
			FlushIO()
		Endif
		
		Return
	End
	
	Method FinishSaving:Void(S:Stream, StreamIsCustom:Bool=False)
		' Local variable(s):
		Local IsOurStream:Bool = (S = IO_Stream)
		
		If (IsOurStream) Then
			Saving = False
		Endif
		
		Super.FinishSaving(S, StreamIsCustom)
		
		'CloseAutoStream(S, StreamIsCustom)
		
		'IO_StreamIsCustom = Default_IO_StreamIsCustom
		'IO_RestoreOnError = Default_IO_RestoreOnError
		
		If (IsOurStream) Then
			FlushIO()
		Endif
		
		Return
	End
	
	Public
	
	' Properties:
	Method CanPause:Bool() Property Final
		Return True
	End
	
	Method Active:Bool() Property
		Return Loading Or Saving
	End
	
	' Fields:
	Field IO_Stream:Stream
	
	' I'm not normally one to do this, but...
	Field IO_StartPosition:Int = -1
	
	Field IO_State:IntObject
	Field IO_ErrorType:IntObject
	
	Field IO_StateStack:Stack<Int> ' = New Stack<Int>()
	
	' Booleans / Flags:
	Field Loading:Bool
	Field Saving:Bool
	
	Field IO_StreamIsCustom:Bool
	Field IO_RestoreOnError:Bool
End

#Rem
	DESCRIPTION:
		This class provides a simple framework for "serializers" which intend to have a similar design for both loading and saving data.
#End

Class StandardIOModel<IOElementType> Extends IOElementType Abstract
	' Constant variable(s):
	Const FileCreator_Unknown:String = "Unknown"
	
	' File constants:
	
	' Standard file-constant template:
	#Rem
		Const FILE_VERSION:Int = INSERT_VERSION_HERE
		Const FILE_CREATOR:String = "Unknown"
		Const FILE_FORMAT_TEXT:String = "FORMAT TEXT HERE"
	#End
	
	' Constructor(s):
	Method New(CanLoad:Bool=Default_CanLoad, CanSave:Bool=Default_CanSave)
		Super.New(CanLoad, CanSave)
	End
	
	' Methods:
	Method Save:Bool(Path:String)
		Return Super.Save(Path)
	End
	
	Method Save:Bool(S:Stream, StreamIsCustom:Bool=False, RestoreOnError:Bool=True)
		' Check for errors:
		If (Not Super.Save(S, StreamIsCustom, RestoreOnError)) Then
			Return False
		Endif
		
		' Local variable(s):
		Local StartPosition:= S.Position
		Local ErrorOccurred:Bool = False
		
		' Begin the file.
		If (Not ErrorOccurred) Then
			WriteInstruction(S, FILE_INSTRUCTION_BEGINFILE)
		Endif
		
		' Write the header:
		If (Not ErrorOccurred) Then
			WriteInstruction(S, FILE_INSTRUCTION_BEGINHEADER)
			
			If (Not WriteHeader(S)) Then
				If (StreamIsCustom) Then
					ErrorOccurred = True
				Endif
			Endif
			
			WriteInstruction(S, FILE_INSTRUCTION_ENDHEADER)
		Endif
		
		' Write the body:
		If (Not ErrorOccurred) Then
			WriteInstruction(S, FILE_INSTRUCTION_BEGINBODY)
			
			If (Not WriteBody(S)) Then
				If (StreamIsCustom) Then
					ErrorOccurred = True
				Endif
			Endif
			
			WriteInstruction(S, FILE_INSTRUCTION_ENDBODY)
		Endif
		
		' Finish the file:
		If (Not ErrorOccurred) Then
			WriteInstruction(S, FILE_INSTRUCTION_ENDFILE)
		Endif
		
		If (ErrorOccurred) Then
			S.Seek(StartPosition)
		Endif
		
		' Finish the saving process.
		FinishSaving(S, StreamIsCustom)
		
		' Return the default response.
		Return True
	End
	
	Method Read_FormatVersion:Int(S:Stream)
		' Check for errors:
		If (S = Null Or S.Eof()) Then Return -1
		
		' Read the version-data from the input-stream.
		Return S.ReadInt()
	End
	
	Method Write_FormatVersion:Bool(S:Stream, Version:Int)
		' Check for errors:
		If (S = Null) Then Return False
		
		' Write the version to the output-stream.
		S.WriteInt(Version)
		
		' Return the default response.
		Return True
	End
	
	Method ReadHeader:Bool(S:Stream, ErrorType:IntObject=Null, State:IntObject=Null)
		' Check for errors:
		If (S = Null Or S.Eof()) Then
			Return False
		Endif
		
		' Local variable(s):
		Local StartPosition:= S.Position
		Local FormatText:String
		
		FormatVersion = Read_FormatVersion(S)
		
		If (Not IsSupportedVersion(FormatVersion)) Then
			If (ErrorType <> Null) Then
				ErrorType.value = ERROR_UNSUPPORTED_VERSION
			Endif
			
			S.Seek(StartPosition)
			
			Return False
		Endif
		
		FormatText = ReadOptString(S)
		
		If (FormatText <> StandardIOModel_FileFormatText) Then ' And FormatText.Length() > 0
			If (ErrorType <> Null) Then
				ErrorType.value = ERROR_INVALID_HEADER
			Endif
			
			S.Seek(StartPosition)
			
			Return False
		Endif
		
		Creator = ReadString(S)
		
		' Return the default response.
		Return True
	End
	
	Method WriteHeader:Bool(S:Stream)
		' Check for errors:
		If (S = Null) Then
			Return False
		Endif
		
		Write_FormatVersion(S, StandardIOModel_FileVersion)
		WriteOptString(S, StandardIOModel_FileFormatText)
		WriteString(S, StandardIOModel_FileCreator)
		
		' Return the default response.
		Return True
	End
	
	Method ReadBody:Bool(S:Stream, ErrorType:IntObject=Null, State:IntObject=Null)
		' Check for errors:
		If (S = Null Or S.Eof()) Then
			Return False
		Endif
		
		' Nothing so far.
		
		' Return the default response.
		Return True
	End
	
	Method WriteBody:Bool(S:Stream)
		' Check for errors:
		If (S = Null) Then
			Return False
		Endif
		
		' Nothing so far.
		
		' Return the default response.
		Return True
	End
	
	' Callbacks:
	Method Loading_OnBeginBody:Bool(S:Stream, ErrorType:IntObject, State:IntObject)
		Return ReadBody(S, ErrorType, State)
	End
	
	Method Loading_OnBeginHeader:Bool(S:Stream, ErrorType:IntObject, State:IntObject)
		Return ReadHeader(S, ErrorType, State)
	End
	
	' Other:
	
	' Implement this as you like, this only serves as a base-implementation.
	Method IsSupportedVersion:Bool(FVersion:Int)
		Return (FVersion <= StandardIOModel_FileVersion)
	End
	
	' Properties (Implemented):
	' Nothing so far.
	
	' Properties (Abstract):
	
	' Following the "Standard file-constant template", this should return 'FILE_VERSION'.
	' In addition, you may implement this as 'Final', however, that is not always ideal, and is not a requirement.
	Method StandardIOModel_FileVersion:Int() Property Abstract
	
	' Following the "Standard file-constant template", this should return 'FILE_FORMAT_TEXT'.
	Method StandardIOModel_FileFormatText:String() Property Abstract
	
	' Following the "Standard file-contant template", this should return 'FILE_CREATOR'.
	' Reimplementing this property is purely optional, and should only be done when an actual creator-string is present.
	Method StandardIOModel_FileCreator:String() Property
		Return FileCreator_Unknown
	End
	
	' Fields:
	Field FormatVersion:Int
	Field Creator:String
End