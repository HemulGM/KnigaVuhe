unit KVU.API;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, HTML.Parser, System.Net.HttpClient,
  KVU.Books, KVU.Playlist;

type
  TKVUAPI = class(TComponent)
  private
    FHTTP: THTTPClient;
    FBaseUrl: string;
    function Get(Url: string): string;
    function GetFullUrl(Path: string): string;
    procedure SetBaseUrl(const Value: string);
    function FGetPlaylist(HtmlText: string; var Playlist: TKVUPlaylist): Boolean;
  public
    //
    function Login(Email, Password: string): Boolean;
    function GetBooks(Path: string; Books: TBooksMeta): Boolean;
    function GetPlaylist(Path: string; var Playlist: TKVUPlaylist): Boolean;
    function GetHtml(Path: string): string;
    function GetBook(Path: string; var Book: TKVUBook): Boolean;
    //
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    //
    property BaseUrl: string read FBaseUrl write SetBaseUrl;
  end;

implementation

constructor TKVUAPI.Create(AOwner: TComponent);
begin
  inherited;
  FHTTP := THTTPClient.Create;
end;

destructor TKVUAPI.Destroy;
begin
  FHTTP.Free;
  inherited;
end;

function TKVUAPI.FGetPlaylist(HtmlText: string; var Playlist: TKVUPlaylist): Boolean;
var
  Str: string;
  Ps, PsE: Integer;
begin
  Result := False;
  Str := HtmlText;
  Ps := Pos('var player = new BookPlayer(', Str);
  PsE := Pos('var player = new BookPlayer(', Str, Ps + 10);
  if PsE > 0 then
    Ps := PsE;
  PsE := Pos(']', Str, Ps);
  Str := Copy(Str, Ps, PsE - Ps + 1);
  Ps := Pos('[', Str);
  Str := Copy(Str, Ps, Length(Str));

  try
    Playlist := TKVUPlaylist.FromJsonString('{ "Items": ' + Str + '}');
    Result := True;
  except
    Exit;
  end;
end;

function TKVUAPI.Get(Url: string): string;
var
  Stream: TStringStream;
begin
  Stream := TStringStream.Create;
  try
    if FHTTP.Get(Url, Stream).StatusCode = 200 then
      Result := UTF8ToString(Stream.DataString);
  finally
    Stream.Free;
  end;
end;

function TKVUAPI.GetBook(Path: string; var Book: TKVUBook): Boolean;
var
  Str: string;
  PL: TKVUPlaylist;
  Parser: TDomTree;
  Nodes: TDomTreeNodeList;
  Values: TStringList;
  Reader: TReader;
  i: Integer;
begin
  Str := Get(GetFullUrl(Path));
  Result := not Str.IsEmpty;
  if not Result then
    Exit;

  Book := TKVUBook.Create;

  if FGetPlaylist(Str, PL) then
    Book.Playlist := PL;

  Parser := TDomTree.Create;
  try
    if Parser.RootNode.Parse(Str) then
    begin
      Nodes := TDomTreeNodeList.Create;
      Values := TStringList.Create;
      try
        if Parser.RootNode.FindPath('./html/body/div[class="scroll_fix"]/div/div/div[class="book_left_blocks"]/div[class="book_title_block"]/div[class="page_title"]/h1/span[itemprop="name"]/text()',
          Nodes, Values) then
        begin
          Book.Name := TLink.Create(Nodes.Items[0].Text, Path);
        end;
        if Parser.RootNode.FindPath('./html/body/div[class="scroll_fix"]/div/div/div[class="book_left_blocks"]/div[1]/div[2]/h1/span[2]/span[itemprop="author"]/a',
          Nodes, Values) then
        begin
          Book.Author := TLink.Create(Nodes.Items[0].Child[0].Text, Nodes.Items[0].Attributes.Items['href'].Trim(['"']));
        end;
        if Parser.RootNode.FindPath('./html/body/div[class="scroll_fix"]/div/div/div[class="book_left_blocks"]/div[1]/div[2]/h1/span[3]/a',
          Nodes, Values) then
        begin
          Book.Reader := TLink.Create(Nodes.Items[0].Child[0].Text, Nodes.Items[0].Attributes.Items['href'].Trim(['"']));
        end;
        if Parser.RootNode.FindPath('./html/body/div[class="scroll_fix"]/div/div/div[class="book_left_blocks"]/div[2]/div[class="book_cover_wrap"]/div[class="book_cover"]/img',
          Nodes, Values) then
        begin
          Book.Image := Nodes.Items[0].Attributes.Items['src'].Trim(['"']);
        end;
        if Parser.RootNode.FindPath('./html/body/div[class="scroll_fix"]/div/div/div[class="book_left_blocks"]/div[2]/div[1]/div[2]',
          Nodes, Values) then
        begin
          Book.Time := Nodes[0].Child[2].Text;
          Book.DateAdd := Nodes[0].Child[6].Text;
        end;
        if Parser.RootNode.FindPath('./html/body/div[class="scroll_fix"]/div/div/div[class="book_left_blocks"]/div[2]/div[2]/div[2]',
          Nodes, Values) then
        begin
          for i := 0 to Nodes[0].Child.Count - 1 do
            if Assigned(Nodes[0].Child[i].Attributes) then
              if Nodes[0].Child[i].Attributes.ContainsValue('book_serie_block_title') then
                Book.Serie.Name := TLink.Create(Nodes[0].Child[i].Child[1].Text, Nodes[0].Child[i].Child[1].Attributes.Items['href'].Trim
                  (['"']));
              //Book.OtherReaders[0].BookUrl :=
          //Book.Image := Nodes.Items[0].Attributes.Items['src'].Trim(['"']);
        end;
      finally
        Nodes.Free;
        Values.Free;
      end;
    end;
  finally
    Parser.Free;
  end;
end;

function TKVUAPI.GetBooks(Path: string; Books: TBooksMeta): Boolean;
var
  Parser: TDomTree;
  Nodes: TDomTreeNodeList;
  Values: TStringList;
  BNodes: TDomTreeNodeList;
  BValues: TStringList;
  i, j, l: Integer;
  HName: string;
  Item: TBookMeta;
begin
  Result := False;
  Parser := TDomTree.Create;
  try
    if Parser.RootNode.Parse(Get(GetFullUrl(Path))) then
    begin
      Nodes := TDomTreeNodeList.Create;
      Values := TStringList.Create;

      BNodes := TDomTreeNodeList.Create;
      BValues := TStringList.Create;
      try
        if Parser.RootNode.FindPath('//*[@id="books_list"]/div', Nodes, Values) then
        begin
          for i := 0 to Nodes.Count - 1 do
          begin
            if Nodes[i].FindPath('/a[class=bookkitem_cover]/img[class=bookkitem_cover_img]', BNodes, BValues) then
              Item.Image := BNodes.Items[0].Attributes.Items['src'].Trim(['"']);

            if Nodes[i].FindPath('/div[class=bookkitem_right]/div[class=bookkitem_name]/a', BNodes, BValues) then
            begin
              HName := '';
              for j := 0 to BNodes.Items[0].Child.Count - 1 do
              begin
                if not BNodes.Items[0].Child[j].Text.Trim.IsEmpty then
                  HName := HName + BNodes.Items[0].Child[j].Text;
                for l := 0 to BNodes.Items[0].Child[j].Child.Count - 1 do
                begin
                  if not BNodes.Items[0].Child[j].Child[l].Text.IsEmpty then
                    HName := HName + ' ' + BNodes.Items[0].Child[j].Child[l].Text;
                end;
              end;
              Item.Name.Text := StringReplace(HName.Trim, '  ', ' ', [rfReplaceAll]);
              Item.Name.Url := BNodes.Items[0].Attributes.Items['href'].Trim(['"']);
            end;

            if Nodes[i].FindPath('/div[class=bookkitem_right]/div[class=bookkitem_name]/span[class=bookkitem_author]/a',
              BNodes, BValues) then
            begin
              HName := '';
              for j := 0 to BNodes.Items[0].Child.Count - 1 do
              begin
                if not BNodes.Items[0].Child[j].Text.Trim.IsEmpty then
                  HName := HName + BNodes.Items[0].Child[j].Text;
                for l := 0 to BNodes.Items[0].Child[j].Child.Count - 1 do
                begin
                  if not BNodes.Items[0].Child[j].Child[l].Text.IsEmpty then
                    HName := HName + ' ' + BNodes.Items[0].Child[j].Child[l].Text;
                end;
              end;
              Item.Author.Text := StringReplace(HName.Trim, '  ', ' ', [rfReplaceAll]);
              Item.Author.Url := BNodes.Items[0].Attributes.Items['href'].Trim(['"']);
            end;

            if Nodes[i].FindPath('/div[class=bookkitem_right]/div[class=bookkitem_genre]/a', BNodes, BValues) then
            begin
              Item.Genre.Text := BNodes.Items[0].Child[0].Text;
              Item.Genre.Url := BNodes.Items[0].Attributes.Items['href'].Trim(['"']);
            end;

            if Nodes[i].FindPath('/div[class=bookkitem_right]/div[class=bookkitem_about]/text()', BNodes, BValues) then
            begin
              Item.About := BNodes.Items[0].Text;
            end;

            if Nodes[i].FindPath('/div[class=bookkitem_right]/div[class=bookkitem_meta]/div[1]/a',
              BNodes, BValues) then
            begin
              Item.Reader.Text := BNodes.Items[0].Child[0].Text;
              Item.Reader.Url := BNodes.Items[0].Attributes.Items['href'].Trim(['"']);
            end;

            if Nodes[i].FindPath('/div[class=bookkitem_right]/div[class=bookkitem_meta]/div[2]/span[class=bookkitem_meta_label]/a',
              BNodes, BValues) then
            begin
              Item.Serie.Text := BNodes.Items[0].Child[0].Text;
              Item.Serie.Url := BNodes.Items[0].Attributes.Items['href'].Trim(['"']);
            end;

            if Nodes[i].FindPath('/div[class=bookkitem_right]/div[class=bookkitem_meta]/div[3]/span[class=bookkitem_meta_time]',
              BNodes, BValues) then
            begin
              Item.Time := BNodes.Items[0].Text;
            end;

            if Nodes[i].FindPath('/div[class=bookkitem_right]/div[class=bookkitem_meta]/div[4]/span[class=bookkitem_meta_label -not_last]',
              BNodes, BValues) then
            begin
              Item.Views := BNodes.Items[0].Text;
            end;

            if Nodes[i].FindPath('/div[class=bookkitem_right]/div[class=bookkitem_meta]/div[4]/a',
              BNodes, BValues) then
            begin
              Item.Comments.Url := BNodes.Items[0].Attributes.Items['href'].Trim(['"']);
            end;

            if Nodes[i].FindPath('/div[class=bookkitem_right]/div[class=bookkitem_meta]/div[4]/a/span[class=bookkitem_meta_label -not_last]',
              BNodes, BValues) then
            begin
              Item.Comments.Url := BNodes.Items[0].Text;
            end;

            if Nodes[i].FindPath('/div[class=bookkitem_right]/div[class=bookkitem_meta]/div[4]/span[4]',
              BNodes, BValues) then
            begin
              Item.Likes := BNodes.Items[0].Text;
            end;
            Books.Add(Item);
          end;
        end;
        if Parser.RootNode.FindPath('//*[@id="books_list__pn"]/div[class="pn_buttons clearfix"]/div[class="pn_page_buttons"]/a',
          Nodes, Values) then
        begin
          if TryStrToInt(Nodes.Last.Child[0].Text, i) then
            Books.PageCount := i
          else
            Books.PageCount := 0;
        end;
        Result := True;
      finally
        Nodes.Free;
        Values.Free;

        BNodes.Free;
        BValues.Free;
      end;
    end;
  finally
    Parser.Free;
  end;
end;

function TKVUAPI.GetFullUrl(Path: string): string;
begin
  Result := FBaseUrl + Path;
end;

function TKVUAPI.GetHtml(Path: string): string;
begin
  Result := Get(GetFullUrl(Path));
end;

function TKVUAPI.GetPlaylist(Path: string; var Playlist: TKVUPlaylist): Boolean;
begin
  Result := FGetPlaylist(Get(GetFullUrl(Path)), Playlist);
end;

function TKVUAPI.Login(Email, Password: string): Boolean;
var
  Resp: TStringStream;
begin
  Result := False;
  Resp := TStringStream.Create;
  try
    if FHTTP.Post(GetFullUrl('/login/?email=' + Email + '&password=' + Password), TStream(nil), Resp).StatusCode = 200 then
    begin
      Result := not Resp.DataString.IsEmpty;
    end;
  finally
    Resp.Free;
  end;
end;

procedure TKVUAPI.SetBaseUrl(const Value: string);
begin
  FBaseUrl := Value;
end;

end.

