<#
.SYNOPSIS
The template gives a good starting point for creating powershell functions and tools.
Start your design with writing out the examples as a functional spesification.
.DESCRIPTION
.PARAMETER
.EXAMPLE
#>

function Search-RDPSessions {
    [CmdletBinding()]
    #^ Optional ..Binding(SupportShouldProcess=$True,ConfirmImpact='Low')
    param (
    [Parameter(Mandatory=$True,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True)]
    [Alias('CN','MachineName','HostName','Name')]
    [string[]]$ComputerName,

    [string]$Username
    )

BEGIN {
    # Intentionaly left empty.
    # Provides optional one-time pre-processing for the function.
    # Setup tasks such as opening database connections, setting up log files, or initializing arrays.
}

PROCESS {
    foreach($computer in $ComputerName){
        Try{
            Write-Verbose "Testing connection to $computer"
            $ConnectionTest = Test-Connection -ComputerName $computer -Count 1 -BufferSize 16 -ErrorAction Stop -ErrorVariable ConnectionFailed
        
            if($ConnectionTest = $True){
                if($PSBoundParameters.ContainsKey('Username')){
                    Write-Verbose "Searching for $Username on $computer"
                    $Sessions = query user $Username /server:$computer
                } #If 
        
                else{
                    Write-Verbose "Searching for RDP sessions on $computer"
                    $Sessions = query user /server:$computer
                } #Else

                foreach($ServerLine in $Sessions -split "\n"){
                    $Parsed_Server = $ServerLine -split '\s+'
                    if($Parsed_Server -like "USERNAME"){
                        Write-Verbose "Found session(s) on $computer"
                        Continue
                    } #If username
            
                    if($Parsed_Server[1] -ne "USERNAME"){

                        if($Parsed_Server[3] -eq 'Disc'){
                            $Username = $Parsed_Server[1]
                            $Sessionname = $null
                            $ID = $Parsed_Server[2]
                            $State = $Parsed_Server[3]
                            $Idletime = $Parsed_Server[4]
                            $Logontime = $Parsed_Server[5]
                    
                            $Parsed_Server[3] = $ID
                            $Parsed_Server[4] = $State
                            $Parsed_Server[5] = $Idletime
                            $Parsed_Server[6] = $Logontime
                            $Parsed_Server[2] = $null
                        } #If disc
                
                        $Properties = @{'ComputerName'=$computer
                                        'UserName'=$Parsed_Server[1]
                                        'SessionName'=$Parsed_Server[2]
                                        'ID'=$Parsed_Server[3]
                                        'State'=$Parsed_Server[4]
                                        'IdleTime'=$Parsed_Server[5]
                                        'LogonTime'=$Parsed_Server[6]}

                        $Obj = New-Object psobject -Property $Properties
                        $Obj
                    }
                } #Foreach serverline
            } #If connectiontest true


        } #Try
        Catch{
            if($ConnectionTest -eq $false -or $ConnectionFailed -ne $null){
                Write-Verbose "*****No ping reply from $computer."
            }
        }
    } #Foreach computer
}


END {
    # Intentionaly left empty.
    # This block is used to provide one-time post-processing for the function.
}

} #Function
