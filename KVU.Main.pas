unit KVU.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.Graphics, FMX.Dialogs, FMX.Controls.Presentation, FMX.Edit, FMX.ScrollBox, FMX.Memo, FMX.StdCtrls,
  System.Net.HttpClient, FMX.Player, KVU.Books, KVU.API, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView, FMX.TabControl, FMX.Objects, System.ImageList, FMX.ImgList, FMX.Ani,
  Radiant.Shapes, FMX.Menus, FMX.MultiView, FMX.Layouts, FMX.ExtCtrls, System.Notification, FMX.Media, FMX.Player.Shared,
  FMX.Player.Windows;

type
  TBitmapHelper = class helper for TBitmap
    procedure LoadFromUrl(const Url: string; UseCache: Boolean = True);
    class function CreateFromUrl(const Url: string): TBitmap;
  end;

  TBitmapCacheItem = record
    Image: TBitmap;
    Url: string;
  end;

  TBitmapCache = TArray<TBitmapCacheItem>;

  TFormMain = class(TForm)
    TabControlMain: TTabControl;
    TabItemSearch: TTabItem;
    TabItemPlayer: TTabItem;
    TabItem3: TTabItem;
    Memo1: TMemo;
    ListViewSearch: TListView;
    Panel1: TPanel;
    EditSearch: TEdit;
    Button3: TButton;
    Edit1: TEdit;
    Button2: TButton;
    Button4: TButton;
    TabItemBook: TTabItem;
    ListViewPL: TListView;
    Panel2: TPanel;
    ButtonPlay: TButton;
    Circle1: TCircle;
    ImageList1: TImageList;
    Panel3: TPanel;
    MultiView1: TMultiView;
    Panel4: TPanel;
    Button1: TButton;
    Label1: TLabel;
    ButtonMenuSearch: TButton;
    ButtonMenuBook: TButton;
    ButtonMenuPlayer: TButton;
    ButtonMenuAbout: TButton;
    StyleBook1: TStyleBook;
    PanelPages: TPanel;
    Panel6: TPanel;
    ButtonSearchNext: TButton;
    LabelPages: TLabel;
    ButtonSearchPrev: TButton;
    AniIndicatorSearch: TAniIndicator;
    Button11: TButton;
    Button12: TButton;
    Panel7: TPanel;
    ButtonSearchTab: TButton;
    LabelBookName: TLabel;
    LabelBookAbout: TLabel;
    Layout1: TLayout;
    ImageBook: TImage;
    Layout2: TLayout;
    LabelBookAuthor: TLabel;
    LabelBookReader: TLabel;
    LabelBookGenre: TLabel;
    VertScrollBox1: TVertScrollBox;
    Layout3: TLayout;
    ButtonBookPlay: TButton;
    Circle2: TCircle;
    LabelBookTime: TLabel;
    FMXPlayer: TFMXPlayer;
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonPlayClick(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ListViewPLItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure ListViewSearchItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure ListViewPLScrollViewChange(Sender: TObject);
    procedure Circle1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ButtonSearchNextClick(Sender: TObject);
    procedure ButtonSearchPrevClick(Sender: TObject);
    procedure ButtonSearchTabClick(Sender: TObject);
    procedure ButtonBookPlayClick(Sender: TObject);
    procedure ButtonMenuPlayerClick(Sender: TObject);
    procedure ButtonMenuSearchClick(Sender: TObject);
    procedure ButtonMenuBookClick(Sender: TObject);
  private
    FAPI: TKVUAPI;
    FSearchPage, FSearchPageCount: Integer;
    FSearchText: string;
    FInSearch: Boolean;
    procedure StartPlay;
    procedure FSearch(Text: string; Page: Integer = 1);
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;
  PictureCache: TBitmapCache;

implementation

uses
  KVU.Playlist;

{$R *.fmx}

function DownloadURL(URL: string): TMemoryStream;
var
  HTTP: THTTPClient;
begin
  Result := TMemoryStream.Create;
  HTTP := THTTPClient.Create;
  try
    try
      HTTP.HandleRedirects := True;
      HTTP.Get(URL, Result);
      Result.Position := 0;
    except
      //Ну, ошибка... Поток всё равно создан и ошибки не должно возникнуть,
      //если проверить размер потока перед его использованием
    end;
  finally
    HTTP.Free;
  end;
end;

procedure LoadImage(Image: TImage; Url: string);
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      Mem: TMemoryStream;
      i: Integer;
    begin
      Image.Bitmap := TBitmap.CreateFromUrl(Url);
      for i := Low(PictureCache) to High(PictureCache) do
        if PictureCache[i].Url = Url then
        begin
          TThread.ForceQueue(nil,
            procedure
            begin
              Image.Bitmap := PictureCache[i].Image;
            end);
          Exit;
        end;
      Mem := DownloadURL(Url);
      try
        i := Length(PictureCache);
        SetLength(PictureCache, i + 1);
        PictureCache[i].Image := TBitmap.Create;
        TThread.Synchronize(nil,
          procedure
          begin
            try
              if Mem.Size > 0 then
              begin
                PictureCache[i].Image.LoadFromStream(Mem);
              end;
            finally
              Image.Bitmap := PictureCache[i].Image;
            end;
          end);
        Mem.Free;
      except
      end;
    end).Start;
end;

procedure TFormMain.ButtonSearchNextClick(Sender: TObject);
begin
  if (FSearchPage < FSearchPageCount) and (not FSearchText.IsEmpty) then
  begin
    Inc(FSearchPage);
    FSearch(FSearchText, FSearchPage);
  end;
end;

procedure TFormMain.ButtonSearchPrevClick(Sender: TObject);
begin
  if (FSearchPage > 1) and (not FSearchText.IsEmpty) then
  begin
    Dec(FSearchPage);
    FSearch(FSearchText, FSearchPage);
  end;
end;

procedure TFormMain.ButtonMenuBookClick(Sender: TObject);
begin
  TabControlMain.SetActiveTabWithTransitionAsync(TabItemBook, TTabTransition.Slide, TTabTransitionDirection.Normal, nil);
  MultiView1.HideMaster;
end;

procedure TFormMain.ButtonMenuPlayerClick(Sender: TObject);
begin
  TabControlMain.SetActiveTabWithTransitionAsync(TabItemPlayer, TTabTransition.Slide, TTabTransitionDirection.Normal, nil);
  MultiView1.HideMaster;
end;

procedure TFormMain.ButtonMenuSearchClick(Sender: TObject);
begin
  TabControlMain.SetActiveTabWithTransitionAsync(TabItemSearch, TTabTransition.Slide, TTabTransitionDirection.Normal, nil);
  MultiView1.HideMaster;
end;

procedure TFormMain.ButtonSearchTabClick(Sender: TObject);
begin
  TabControlMain.SetActiveTabWithTransitionAsync(TabItemSearch, TTabTransition.Slide, TTabTransitionDirection.Normal, nil);
end;

procedure TFormMain.ButtonBookPlayClick(Sender: TObject);
begin
  TabControlMain.SetActiveTabWithTransitionAsync(TabItemPlayer, TTabTransition.Slide, TTabTransitionDirection.Normal, nil);
end;

procedure TFormMain.Button1Click(Sender: TObject);
begin
  MultiView1.ShowMaster;
end;

procedure TFormMain.Button2Click(Sender: TObject);
var
  PL: TKVUPlaylist;
  i: Integer;
begin
  if FAPI.GetPlaylist(Edit1.Text, PL) then
  begin
    for i := Low(PL.Items) to High(PL.Items) do
    begin
      Memo1.Lines.Add(PL.Items[i].Title);
      Memo1.Lines.Add(PL.Items[i].URL);
      Memo1.Lines.Add('--');
    end;

    PL.Free;
  end;
end;

procedure TFormMain.FSearch(Text: string; Page: Integer);
begin
  if FInSearch then
    Exit;
  FInSearch := True;
  FSearchText := Text;
  FSearchPage := Page;

  ListViewSearch.BeginUpdate;
  AniIndicatorSearch.Enabled := True;
  AniIndicatorSearch.Visible := True;
  ListViewSearch.Items.Clear;
  TThread.CreateAnonymousThread(
    procedure
    var
      FBooks: TBooksMeta;
    begin
      FBooks := TBooksMeta.Create;
      try
        if FAPI.GetBooks('/search/?q=' + FSearchText + '&page=' + FSearchPage.ToString, FBooks) then
        begin
          TThread.Synchronize(TThread.Current,
            procedure
            var
              i: Integer;
            begin
              for i := 0 to FBooks.Count - 1 do
              begin
                with ListViewSearch.Items.Add do
                begin
                  Text := FBooks[i].Name.Text;
                  Detail := FBooks[i].Author.Text + #13#10 + FBooks[i].Reader.Text;
                  ButtonText := FBooks[i].Name.Url;
                end;
              end;
              FSearchPageCount := FBooks.PageCount;
            end);
        end;
      finally
        FBooks.Free;
        FInSearch := False;
        TThread.Synchronize(TThread.Current,
          procedure
          begin
            AniIndicatorSearch.Enabled := False;
            AniIndicatorSearch.Visible := False;
            PanelPages.Visible := FSearchPageCount > 0;
            ButtonSearchPrev.Enabled := True;
            ButtonSearchNext.Enabled := True;
            LabelPages.Enabled := True;
            LabelPages.Text := FSearchPage.ToString + '/' + FSearchPageCount.ToString;
            ListViewSearch.EndUpdate;
          end);
      end;
    end).Start;
end;

procedure TFormMain.Button3Click(Sender: TObject);
begin
  FSearch(EditSearch.Text);
end;

procedure TFormMain.Button4Click(Sender: TObject);
begin
  Memo1.Lines.Add(FAPI.GetHtml(Edit1.Text));
end;

procedure TFormMain.ButtonPlayClick(Sender: TObject);
begin
  if FMXPlayer.IsPlay then
  begin
    FMXPlayer.Pause;
    ButtonPlay.StyleLookup := 'playtoolbutton';
  end
  else
  begin
    if FMXPlayer.IsPause then
      FMXPlayer.Resume
    else
      StartPlay;
    ButtonPlay.StyleLookup := 'pausetoolbutton';
  end;
end;

procedure TFormMain.Circle1Click(Sender: TObject);
begin
  TAnimator.AnimateFloat(ListViewPL, 'ScrollViewPos', 0, 0.3, TAnimationType.&Out, TInterpolationType.Quadratic);
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  TabControlMain.TabPosition := TTabPosition.None;
  FAPI := TKVUAPI.Create(Self);
  FAPI.BaseUrl := 'https://knigavuhe.org';
  if not FMXPlayer.Init(Handle) then
  begin
    ShowMessage('Аудио не инициализировано ' + FMXPlayer.GetLibPath);
  end;
  //if FAPI.Login('alinvip@inbox.ru', 'aVIPs22031994') then
  //  ShowMessage('login'); //
end;

procedure TFormMain.FormDestroy(Sender: TObject);
var
  i: Integer;
begin
  for i := Low(PictureCache) to High(PictureCache) do
    PictureCache[i].Image.Free;
  FAPI.Free;
  FMXPlayer.Free;
end;

procedure TFormMain.StartPlay;
begin
  ListViewPL.Enabled := False;
  TThread.CreateAnonymousThread(
    procedure
    begin
      FMXPlayer.Play;
      TThread.Synchronize(nil,
        procedure
        begin
          ListViewPL.Enabled := True;
          //
        end);
    end).Start;
end;

procedure TFormMain.ListViewPLItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  FMXPlayer.SetStreamURL(AItem.ButtonText);
  ButtonPlay.StyleLookup := 'pausetoolbutton';
  StartPlay;
end;

procedure TFormMain.ListViewPLScrollViewChange(Sender: TObject);
begin
  if ListViewPL.ScrollViewPos > 200 then
  begin
    if Circle1.Opacity <= 0 then
    begin
      Circle1.Opacity := 0.002;
      TAnimator.AnimateFloat(Circle1, 'Opacity', 1);
    end;
  end
  else
  begin
    if Circle1.Opacity >= 1 then
    begin
      Circle1.Opacity := 0.999;
      TAnimator.AnimateFloat(Circle1, 'Opacity', 0);
    end;
  end;
end;

procedure TFormMain.ListViewSearchItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  Book: TKVUBook;
  i: Integer;
begin
  if FAPI.GetBook(AItem.ButtonText, Book) then
  begin
    ListViewPL.BeginUpdate;
    ListViewPL.Items.Clear;
    LoadImage(ImageBook, Book.Image);
    LabelBookName.Text := Book.Name.Text;
    LabelBookAuthor.Text := 'автор ' + Book.Author.Text;
    LabelBookAuthor.Hint := Book.Author.Url;
    LabelBookReader.Text := 'читает ' + Book.Reader.Text;
    LabelBookReader.Hint := Book.Reader.Url;
    LabelBookAbout.Text := Book.About;
    LabelBookTime.Text := 'Время звучания: ' + Book.Time + #13#10 + 'Дата добавления: ' + Book.DateAdd;
    for i := Low(Book.Playlist.Items) to High(Book.Playlist.Items) do
    begin
      with ListViewPL.Items.Add do
      begin
        Text := Book.Playlist.Items[i].Title;
        Detail := Book.Playlist.Items[i].Duration.ToString;
        ButtonText := Book.Playlist.Items[i].URL;
        ImageIndex := 0;
      end;
    end;
    Book.Free;
    ListViewPL.EndUpdate;
  end;

  TabControlMain.SetActiveTabWithTransitionAsync(TabItemBook, TTabTransition.Slide, TTabTransitionDirection.Normal, nil);
end;

{ TBitmapHelper }

class function TBitmapHelper.CreateFromUrl(const Url: string): TBitmap;
var
  i: Integer;
begin
  for i := Low(PictureCache) to High(PictureCache) do
    if PictureCache[i].Url = Url then
    begin
      TThread.Queue(TThread.Current,
        procedure
        begin
          FormMain.ImageBook.Repaint;
        end);
      Exit(PictureCache[i].Image);
    end;
  i := Length(PictureCache);
  SetLength(PictureCache, i + 1);
  PictureCache[i].Image := TBitmap.Create;
  PictureCache[i].Image.LoadFromUrl(Url, False);
  Result := PictureCache[i].Image;
end;

procedure TBitmapHelper.LoadFromUrl(const Url: string; UseCache: Boolean);
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      Mem: TMemoryStream;
      i: Integer;
    begin
      if UseCache then
        for i := Low(PictureCache) to High(PictureCache) do
          if PictureCache[i].Url = Url then
          begin
            Self.Assign(PictureCache[i].Image);
            TThread.Queue(TThread.Current,
              procedure
              begin
                FormMain.ImageBook.Repaint;
              end);
            Exit;
          end;

      Mem := DownloadURL(Url);
      try
        i := Length(PictureCache);
        SetLength(PictureCache, i + 1);
        PictureCache[i].Image := TBitmap.Create;
        try
          if Mem.Size > 0 then
          begin
            PictureCache[i].Image.LoadFromStream(Mem);
          end;
        finally
          Self.Assign(PictureCache[i].Image);
          Mem.Free;
        end;
      except
      end;
      TThread.ForceQueue(nil,
        procedure
        begin
          FormMain.ImageBook.Repaint;
        end);
    end).Start;
end;

end.

