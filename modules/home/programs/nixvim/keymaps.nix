{ config
, lib
, ...
}:

let
  cfg = config.my.programs.nixvim;

  silent = {
    silent = true;
    noremap = true;
  };
in
{
  config = lib.mkIf cfg.enable {
    programs.nixvim.keymaps = [
      # Lưu và thoát
      {
        mode = "n";
        key = "<leader>w";
        action = "<cmd>write<cr>";
        options = silent // {
          desc = "Lưu tệp";
        };
      }
      {
        mode = "n";
        key = "<leader>q";
        action = "<cmd>quit<cr>";
        options = silent // {
          desc = "Đóng cửa sổ";
        };
      }
      {
        mode = "n";
        key = "<leader>Q";
        action = "<cmd>qa!<cr>";
        options = silent // {
          desc = "Thoát toàn bộ không lưu";
        };
      }

      # Bỏ tô sáng tìm kiếm
      {
        mode = "n";
        key = "<Esc>";
        action = "<cmd>nohlsearch<cr>";
        options = silent;
      }

      # Di chuyển giữa các cửa sổ
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
        options = silent // {
          desc = "Cửa sổ bên trái";
        };
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
        options = silent // {
          desc = "Cửa sổ bên dưới";
        };
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
        options = silent // {
          desc = "Cửa sổ bên trên";
        };
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
        options = silent // {
          desc = "Cửa sổ bên phải";
        };
      }

      # Thay đổi kích thước cửa sổ
      {
        mode = "n";
        key = "<C-Up>";
        action = "<cmd>resize +2<cr>";
        options = silent;
      }
      {
        mode = "n";
        key = "<C-Down>";
        action = "<cmd>resize -2<cr>";
        options = silent;
      }
      {
        mode = "n";
        key = "<C-Left>";
        action = "<cmd>vertical resize -2<cr>";
        options = silent;
      }
      {
        mode = "n";
        key = "<C-Right>";
        action = "<cmd>vertical resize +2<cr>";
        options = silent;
      }

      # Di chuyển dòng đang chọn
      {
        mode = "v";
        key = "J";
        action = ":m '>+1<cr>gv=gv";
        options = silent // {
          desc = "Di chuyển xuống";
        };
      }
      {
        mode = "v";
        key = "K";
        action = ":m '<-2<cr>gv=gv";
        options = silent // {
          desc = "Di chuyển lên";
        };
      }

      # Giữ vùng chọn sau khi thụt dòng
      {
        mode = "v";
        key = "<";
        action = "<gv";
        options = silent;
      }
      {
        mode = "v";
        key = ">";
        action = ">gv";
        options = silent;
      }

      # Điều khiển buffer
      {
        mode = "n";
        key = "<S-h>";
        action = "<cmd>bprevious<cr>";
        options = silent // {
          desc = "Buffer trước";
        };
      }
      {
        mode = "n";
        key = "<S-l>";
        action = "<cmd>bnext<cr>";
        options = silent // {
          desc = "Buffer sau";
        };
      }
      {
        mode = "n";
        key = "<leader>bd";
        action = "<cmd>bdelete<cr>";
        options = silent // {
          desc = "Đóng buffer";
        };
      }

      # Terminal
      {
        mode = "t";
        key = "<Esc><Esc>";
        action = "<C-\\><C-n>";
        options = silent // {
          desc = "Thoát chế độ nhập terminal";
        };
      }

      # Sửa nhanh cấu hình NixOS
      {
        mode = "n";
        key = "<leader>nc";
        action = "<cmd>edit /etc/nixos/flake.nix<cr>";
        options = silent // {
          desc = "Mở flake.nix";
        };
      }
    ];
  };
}
