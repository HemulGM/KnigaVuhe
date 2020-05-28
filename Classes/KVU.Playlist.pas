unit KVU.Playlist;

interface

uses
  Generics.Collections, Rest.Json;

type
  TKVUAudio = class
  private
    FDuration: Extended;
    FDuration_float: Extended;
    FError: Extended;
    FId: Extended;
    FTitle: string;
    FUrl: string;
  public
    property Duration: Extended read FDuration write FDuration;
    property DurationFloat: Extended read FDuration_float write FDuration_float;
    property Error: Extended read FError write FError;
    property Id: Extended read FId write FId;
    property Title: string read FTitle write FTitle;
    property Url: string read FUrl write FUrl;
    function ToJsonString: string;
    class function FromJsonString(AJsonString: string): TKVUAudio;
  end;

  TKVUPlaylist = class
  private
    FItems: TArray<TKVUAudio>;
  public
    property Items: TArray<TKVUAudio> read FItems write FItems;
    destructor Destroy; override;
    function ToJsonString: string;
    class function FromJsonString(AJsonString: string): TKVUPlaylist;
  end;

implementation

{TKVUAudio}

function TKVUAudio.ToJsonString: string;
begin
  Result := TJson.ObjectToJsonString(self);
end;

class function TKVUAudio.FromJsonString(AJsonString: string): TKVUAudio;
begin
  Result := TJson.JsonToObject<TKVUAudio>(AJsonString)
end;

{TKVUPlaylist}

destructor TKVUPlaylist.Destroy;
var
  LItemsItem: TKVUAudio;
begin

  for LItemsItem in FItems do
    LItemsItem.Free;

  inherited;
end;

function TKVUPlaylist.ToJsonString: string;
begin
  Result := TJson.ObjectToJsonString(self);
end;

class function TKVUPlaylist.FromJsonString(AJsonString: string): TKVUPlaylist;
begin
  Result := TJson.JsonToObject<TKVUPlaylist>(AJsonString)
end;

end.

