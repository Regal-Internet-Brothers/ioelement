Strict

Public

' Imports:
Import ioelement

' Functions:
Function Main:Int()
	' Local variable(s):
	Local Location:String = "Test.file"
	
	' Create a new 'TestElement' object.
	Local E:= New TestElement(1234.5)
	
	' Serialize the element to the disk.
	E.Save(Location)
	
	' Make a new one from scratch.
	E = New TestElement()
	
	' Load the contents of the element from the disk.
	E.Load(Location)
	
	' Output the element's contents.
	Print(E.X)
	
	' Return the default response.
	Return 0
End

' Classes:

' A very basic file-format that houses a floating-point value.
Class TestElement Extends StandardIOModel<StructuredIOElement> Final
	' Constant variable(s):
	Const FILE_CREATOR:String = "'IOElement' Example Program"
	Const FILE_FORMAT_TEXT:String = "TEST"
	Const FILE_VERSION:Int = 1
	
	' Constructor(s):
	Method New(X:Float=0.0)
		' Call the super-class's implementation.
		Super.New(True, True)
		
		Self.X = X
	End
	
	' Methods:
	
	' Call-backs:
	Method Loading_OnBeginBody:Bool(S:Stream, ErrorType:IntObject, State:IntObject)
		' Check for errors:
		If (Not Super.Loading_OnBeginBody(S, ErrorType, State)) Then
			Return False
		Endif
		
		X = S.ReadFloat()
		
		' Return the default response.
		Return True
	End
	
	Method WriteBody:Bool(S:Stream)
		' Check for errors:
		If (Not Super.WriteBody(S)) Then
			Return False
		Endif
		
		S.WriteFloat(X)
		
		' Return the default response.
		Return True
	End
	
	' Properties:
	
	' Meta:
	Method StandardIOModel_FileVersion:Int() Property
		Return FILE_VERSION
	End
	
	Method StandardIOModel_FileFormatText:String() Property
		Return FILE_FORMAT_TEXT
	End
	
	Method StandardIOModel_FileCreator:String() Property
		Return FILE_CREATOR
	End
	
	' Fields:
	Field X:Float
End