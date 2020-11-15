//=============================================================================
// Play custom sounds with mutate commands
// Made by Vel-San @ https://steamcommunity.com/id/Vel-San/
//=============================================================================

class KFSoundBoard extends Mutator Config(SoundBoardConfig);

// SoundPack exec goes here

// Config Vars
var() config bool bDebug;
var() config int iDelay;

// Sound Declaration Struct
struct CS
{
  var config string Sound; // Name of sound in the SoundPack, e.g. XX.YY
  var config string SoundTag; // Tag for human readbility, doesn't affect anything
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
  // Generate Default Config File, keep commented unless you want to generate one yourself
  // SaveConfig();

  if(bDebug)
  {
    MutLog("-----|| Found [" $SoundList.Length$ "] Sounds in Config File ||-----");
  }
}

function Mutate(string command, PlayerController Sender)
{
  local string PN, PID, WelcomeMSG, DelayMSG, TotalSoundsMSG, UsageMSG, PrintSoundsMSG;
  local array<string> SplitCMD;

  PN = Sender.PlayerReplicationInfo.PlayerName;
  PID = Sender.GetPlayerIDHash();

  if(bDebug)
	{
		MutLog("-----|| DEBUG - '" $command$ "' accessed by: " $PN$ " | PID: " $PID$  " ||-----");
	}

  SplitStringToArray(SplitCMD, command, " ");

  if(command ~= "sb help" || command ~= "soundboard help")
	{
		WelcomeMSG = "%yYou are viewing Sound-Board Help, below are the commands you can use";
		DelayMSG = "%bDelay between sounds (seconds): %w" $iDelay;
		TotalSoundsMSG = "%bTotal Sounds: %w" $SoundList.Length;
		UsageMSG = "%bUsage: %wmutate %tXXX%w | XXX is the tag of the sound you want to play";
    PrintSoundsMSG = "%bTo view all available sounds: %wmutate %t!sounds %wOR %t!snds";

    SetColor(WelcomeMSG);
		SetColor(DelayMSG);
		SetColor(TotalSoundsMSG);
		SetColor(UsageMSG);
		SetColor(PrintSoundsMSG);

    Sender.ClientMessage(WelcomeMSG);
		Sender.ClientMessage(DelayMSG);
		Sender.ClientMessage(TotalSoundsMSG);
		Sender.ClientMessage(UsageMSG);
		Sender.ClientMessage(PrintSoundsMSG);

		return;
	}

  if(command ~= "!sounds" || command ~= "!snds" )
  {
    PrintAllSounds(SoundList, Sender);
  }

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

function PrintAllSounds(array<CS> Sounds, PlayerController PC)
{
  local string TmpSoundMSG;
  local int i;
  for(i=0; i<Sounds.Length; i++)
  {
    if(Sounds[i].Sound != "" && Sounds[i].SoundTag != "" && Sounds[i].SoundBind != "")
    {
      TmpSoundMSG = "%wSound: %b" $Sounds[i].SoundTag$ "%w | Bind: %t" $Sounds[i].SoundBind;
      SetColor(TmpSoundMSG);
      PC.ClientMessage(TmpSoundMSG);
    }
  }
}

function TimeStampLog(coerce string s)
{
  log("["$Level.TimeSeconds$"s]" @ s, 'SoundBoard');
}

function MutLog(string s)
{
  log(s, 'SoundBoard');
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
  bDebug = True
  iDelay = 3
}