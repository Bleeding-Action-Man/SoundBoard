//=============================================================================
// Play custom sounds with mutate commands
// Made by Vel-San @ https://steamcommunity.com/id/Vel-San/
//=============================================================================

class KFSoundBoard extends Mutator Config(SoundBoardConfig);

// SoundPack exec goes here

// Config Vars
var() config bool bDebug;

// Sound Declaration Struct
struct CS
{
  var config sound Sound; // Name of sound in the SoundPack
  var config string SoundName; // Name for human readbility, doesn't affect anything
  var config string SoundBind; // Bind to be used with mutate, e.g. mutate meow
};
var() config array<CS> SoundList; // SoundsList

// Colors from Config
struct ColorRecord
{
  var config string ColorName; // Color name, for comfort
  var config string ColorTag; // Color tag
  var config Color Color; // RGBA values
};
var() config array<ColorRecord> ColorList; // Color list


// Initialization
function PostBeginPlay()
{
  if(bDebug)
  {
    MutLog("-----|| Found [" $SoundList.Length$ "] Sounds in Config File ||-----");
  }
}

function Mutate(string command, PlayerController Sender)
{
  local string PN, PID;
  local array<string> SplitCMD;

  PN = Sender.PlayerReplicationInfo.PlayerName;
  PID = Sender.GetPlayerIDHash();

  if(Debug)
	{
		MutLog("-----|| DEBUG - '" $command$ "' accessed by: " $PN$ " | PID: " $PID$  " ||-----");
	}

  SplitStringToArray(SplitCMD, command, " ");

  // If command = XX -- Goes Here
}

final function SplitStringToArray(out array<string> Parts, string Source, string Delim)
{
  Split(Source, Delim, Parts);
}

function ServerMessage(string Msg)
{
	local Controller C;
	local PlayerController PC;
	for (C = Level.ControllerList; C != none; C = C.nextController)
	{
		PC = PlayerController(C);
		if (PC != none)
		{
			SetColor(Msg);
			PC.ClientMessage(Msg);
		}
	}
}

function CriticalServerMessage(string Msg)
{
	local Controller C;
	local PlayerController PC;
	for (C = Level.ControllerList; C != none; C = C.nextController)
	{
		PC = PlayerController(C);
		if (PC != none)
		{
			SetColor(Msg);
			PC.ClientMessage(Msg, 'CriticalEvent');
		}
	}
}

function TimeStampLog(coerce string s)
{
  log("["$Level.TimeSeconds$"s]" @ s, 'SkipTrader');
}

function MutLog(string s)
{
  log(s, 'SkipTrader');
}

/////////////////////////////////////////////////////////////////////////
// BELOW SECTION IS CREDITED FOR NikC //

// Apply Color Tags To Message
function SetColor(out string Msg)
{
  local int i;
  for(i=0; i<ColorList.Length; i++)
  {
    if(ColorList[i].ColorTag!="" && InStr(Msg, ColorList[i].ColorTag)!=-1)
    {
      ReplaceText(Msg, ColorList[i].ColorTag, FormatTagToColorCode(ColorList[i].ColorTag, ColorList[i].Color));
    }
  }
}

// Format Color Tag to ColorCode
function string FormatTagToColorCode(string Tag, Color Clr)
{
  Tag=Class'GameInfo'.Static.MakeColorCode(Clr);
  Return Tag;
}

function string RemoveColor(string S)
{
  local int P;
  P=InStr(S,Chr(27));
  While(P>=0)
  {
    S=Left(S,P)$Mid(S,P+4);
    P=InStr(S,Chr(27));
  }
  Return S;
}
//////////////////////////////////////////////////////////////////////

defaultproperties
{
  // Mandatory Vars
	GroupName = "KF-SoundBoard"
  FriendlyName = "Sound Board - v1.0"
  Description = "Play custom sounds with key binds / mutate commands; Made by Vel-San"
	bAddToServerPackages=true

  // Config Vars
  bDebug=True
}