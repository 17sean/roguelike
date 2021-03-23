unit slib;
interface

function SrI(s: string): longint; { String returns integer }
function IrS(i: longint): string; { Integer returns string }
function DFE(dir: string): boolean; { Does file exist? }
function StringShorter(s: string; pos: integer): string;
function ParserShorter(s: string): string;

implementation

function SrI(s: string): longint;
var
    i: integer;
    res: longint;
    negative: boolean;
begin
    res := 0;
    negative := false;
    for i := 1 to length(s) do
    begin
        if (i = 1) and (s[1] = '-') then
            negative := true
        else
        begin
            res *= 10;
            res += ord(s[i]) - ord('0');
        end;
    end;
    if negative then
        res *= -1;
    SrI := res;
end;

function IrS(i: longint): string;
type
    pCharEl = ^CharEl;
    CharEl = record
        data: char;
        next: pCharEl;
    end;
var
    p, tmp: pCharEl;
    s: string;
    j: longint;
begin
    if i = 0 then
    begin
        IrS := '0';
        exit;
    end;

    p := nil;
    s := ''; 
    j := i;
    if i < 0 then
        i := -i;
    while i <> 0 do
    begin
        new(tmp);
        if (i mod 10) <> 0 then
            tmp^.data := chr(ord(i mod 10) + ord('0'))
        else
            tmp^.data := '0';
        i := i div 10;
        tmp^.next := p;
        p := tmp;
    end;
    if j < 0 then
        s += '-';
    while tmp <> nil do
    begin
        s += tmp^.data;
        tmp := tmp^.next;
    end;
    while p <> nil do
    begin
        tmp := p;
        p := p^.next;
        dispose(tmp);
    end;
    IrS := s;
end;

function DFE(dir: string): boolean;
var
    f: file;
begin
    assign(f, dir);
    {$I-}
    reset(f);
    if IOresult = 0 then
    begin
        DFE := true;
        close(f);
    end
    else
        DFE := false;
    {$I+}
end;

function StringShorter(s: string; pos: integer): string;
var
    tmp: string;
begin
    tmp := '';
    while s[pos] <> ';' do
    begin
        tmp += s[pos];
        pos += 1;
    end;
    StringShorter := tmp;
end;

function ParserShorter(s: string): string;
var
    pos: integer;
begin
    pos := 1;
    while s[pos] <> ':' do
        pos += 1;
    ParserShorter := StringShorter(s, pos+1);
end;

end.
