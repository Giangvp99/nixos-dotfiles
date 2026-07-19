{ config
, lib
, ...
}:

let
  cfg = config.my.programs.nixvim;
in
{
  config = lib.mkIf cfg.enable {
    programs.nixvim.opts = {
      # Số dòng
      number = true;
      relativenumber = true;

      # Dòng và cột hiện tại
      cursorline = true;
      colorcolumn = "100";

      # Khoảng lề
      signcolumn = "yes";
      numberwidth = 4;

      # Thụt dòng
      expandtab = true;
      tabstop = 2;
      softtabstop = 2;
      shiftwidth = 2;
      smartindent = true;
      breakindent = true;

      # Tìm kiếm
      ignorecase = true;
      smartcase = true;
      hlsearch = true;
      incsearch = true;

      # Hiển thị
      wrap = false;
      scrolloff = 8;
      sidescrolloff = 8;
      termguicolors = true;
      showmode = false;

      # Chia cửa sổ
      splitbelow = true;
      splitright = true;

      # Chuột và clipboard
      mouse = "a";
      clipboard = "unnamedplus";

      # Hoàn thành
      completeopt = [
        "menu"
        "menuone"
        "noselect"
      ];

      # Tệp sao lưu và lịch sử
      swapfile = false;
      backup = false;
      undofile = true;

      # Phản hồi
      updatetime = 250;
      timeoutlen = 400;

      # Xác nhận thay vì lỗi khi buffer chưa lưu
      confirm = true;

      # Tìm kiếm thay thế trực quan
      inccommand = "split";

      # Gấp mã bằng Tree-sitter, mặc định mở hết
      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;
    };
  };
}
