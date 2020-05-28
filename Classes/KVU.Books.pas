unit KVU.Books;

interface

uses
  System.Generics.Collections, KVU.Playlist;

type
  TLink = record
    Text: string;
    Url: string;
    class function Create(Text, Url: string): TLink; static;
  end;

  TLinks = TList<TLink>;

  TBookMeta = record
    Name: TLink;
    Author: TLink;
    Reader: TLink;
    Genre: TLink;
    Serie: TLink;
    Comments: TLink;
    Views: string;
    Likes: string;
    Time: string;
    About: string;
    Image: string;
  end;

  TBooksMeta = class(TList<TBookMeta>)
  private
    FPageCount: Integer;
    procedure SetPageCount(const Value: Integer);
  public
    property PageCount: Integer read FPageCount write SetPageCount;
  end;

  TReader = record
    BookUrl: string;
    Reader: TLink;
  end;

  TReaders = TList<TReader>;

  TSerie = class(TLinks)
    Name: TLink;
  end;

  TKVUBook = class
  private
    FOtherReaders: TReaders;
    FName: TLink;
    FDateAdd: string;
    FFavs: string;
    FImage: string;
    FLikes: string;
    FSerie: TSerie;
    FAbout: string;
    FTime: string;
    FGenres: TLinks;
    FViews: string;
    FPlaylist: TKVUPlaylist;
    FAuthor: TLink;
    FReader: TLink;
    procedure SetAbout(const Value: string);
    procedure SetDateAdd(const Value: string);
    procedure SetFavs(const Value: string);
    procedure SetGenres(const Value: TLinks);
    procedure SetImage(const Value: string);
    procedure SetLikes(const Value: string);
    procedure SetName(const Value: TLink);
    procedure SetOtherReaders(const Value: TReaders);
    procedure SetSerie(const Value: TSerie);
    procedure SetTime(const Value: string);
    procedure SetViews(const Value: string);
    procedure SetPlaylist(const Value: TKVUPlaylist);
    procedure SetAuthor(const Value: TLink);
    procedure SetReader(const Value: TLink);
  public
    property OtherReaders: TReaders read FOtherReaders write SetOtherReaders;
    property Image: string read FImage write SetImage;
    property Name: TLink read FName write SetName;
    property Author: TLink read FAuthor write SetAuthor;
    property Reader: TLink read FReader write SetReader;
    property Serie: TSerie read FSerie write SetSerie;
    property Genres: TLinks read FGenres write SetGenres;
    property About: string read FAbout write SetAbout;
    property Views: string read FViews write SetViews;
    property Likes: string read FLikes write SetLikes;
    property Favs: string read FFavs write SetFavs;
    property Time: string read FTime write SetTime;
    property DateAdd: string read FDateAdd write SetDateAdd;
    property Playlist: TKVUPlaylist read FPlaylist write SetPlaylist;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TBooks }

procedure TBooksMeta.SetPageCount(const Value: Integer);
begin
  FPageCount := Value;
end;

{ TBook }

constructor TKVUBook.Create;
begin
  FOtherReaders := TReaders.Create;
  FSerie := TSerie.Create;
  FGenres := TLinks.Create;
  FPlaylist := TKVUPlaylist.Create;
end;

destructor TKVUBook.Destroy;
begin
  FOtherReaders.Free;
  FSerie.Free;
  FGenres.Free;
  FPlaylist.Free;
  inherited;
end;

procedure TKVUBook.SetAbout(const Value: string);
begin
  FAbout := Value;
end;

procedure TKVUBook.SetAuthor(const Value: TLink);
begin
  FAuthor := Value;
end;

procedure TKVUBook.SetDateAdd(const Value: string);
begin
  FDateAdd := Value;
end;

procedure TKVUBook.SetFavs(const Value: string);
begin
  FFavs := Value;
end;

procedure TKVUBook.SetGenres(const Value: TLinks);
begin
  FGenres := Value;
end;

procedure TKVUBook.SetImage(const Value: string);
begin
  FImage := Value;
end;

procedure TKVUBook.SetLikes(const Value: string);
begin
  FLikes := Value;
end;

procedure TKVUBook.SetName(const Value: TLink);
begin
  FName := Value;
end;

procedure TKVUBook.SetOtherReaders(const Value: TReaders);
begin
  FOtherReaders := Value;
end;

procedure TKVUBook.SetPlaylist(const Value: TKVUPlaylist);
begin
  if Assigned(FPlaylist) then
    FPlaylist.Free;
  FPlaylist := Value;
end;

procedure TKVUBook.SetReader(const Value: TLink);
begin
  FReader := Value;
end;

procedure TKVUBook.SetSerie(const Value: TSerie);
begin
  FSerie := Value;
end;

procedure TKVUBook.SetTime(const Value: string);
begin
  FTime := Value;
end;

procedure TKVUBook.SetViews(const Value: string);
begin
  FViews := Value;
end;

{ TLink }

class function TLink.Create(Text, Url: string): TLink;
begin
  Result.Text := Text;
  Result.Url := Url;
end;

end.

