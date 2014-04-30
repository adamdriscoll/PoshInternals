function ConvertTo-Object {
	[CmdletBinding()]
	param(
		[Parameter()]
		[IntPtr]$Ptr,
		[Parameter()]
		[Type]$Type
		)

	Process {
		[System.Runtime.InteropServices.Marshal]::PtrToStructure($Ptr, [Type]$Type)
	}
}

function ConvertTo-Pointer {
	[CmdletBinding()]
	param(
		[Parameter()]
		$Object
		)

	Process {
		$Size = [System.Runtime.InteropServices.Marshal]::SizeOf($Object)
		[IntPtr]$ptr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($Size)
		[System.Runtime.InteropServices.Marshal]::StructureToPtr($Object, $ptr, $false)

		$ptr 
	}
}

function ConvertTo-String {
	[CmdletBinding()]
	param(
		[Parameter()]
		[IntPtr]$Ptr,
		[Parameter()]
		[Switch]$Ansi
		)

	Process {
		if ($Ansi)
		{
			[System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($Ptr)
		}
		else
		{
			[System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
		}
	}
}

function Get-Size {
[CmdletBinding()]
	param(
		[Parameter()]
		[Object]$Object,
		[Parameter()]
		[Type]$Type)

	if ($Type)
	{
		[System.Runtime.InteropServices.Marshal]::SizeOf([Type]$type)
	}
	else
	{
		[System.Runtime.InteropServices.Marshal]::SizeOf($Object)
	}
}