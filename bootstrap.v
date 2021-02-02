import cli { Command, Flag }
import os
struct Program {
  name 				string
  // Mapping package manager names to install commands
  install 		map[string]string
  website 		string
}

struct SimpleProgram {
  name string
  install string
}

fn detect_distro() ?string {
  if os.exists('/usr/bin/lsb_release') {
    res := os.exec('/usr/bin/lsb_release -s -i') ?
    return res.output.to_lower().trim_suffix("\n")
  } else if os.exists('/etc/os-release') {
    lines := os.read_lines('/etc/os-release') ?
    
    filtered := lines.filter(fn (line string) bool {
      return line.starts_with('ID=')
    })

    if filtered.len >= 1 {
      return filtered[0].trim_prefix('ID=').to_lower()
    } else {
      return 'unknown'
    }
  } else if os.exists('/etc/debian_version') {
    return 'debian'
  }
  return 'unknown'
}

fn detect_pacman(distro string) string {
  match distro {
    'manjarolinux', 'archlinux' { 
      if os.exists_in_system_path('paru') {
        return 'paru'
      } else if os.exists_in_system_path('yay') {
        return 'yay'
      }
      return 'pacman'
    }
    'ubuntu', 'debian' 					{ return 'apt'     }
    'alpine' 										{ return 'apk'     }
    else 												{ return 'unknown' }
  }
}

fn simple_install(program SimpleProgram) {
  println("[*] Installing $program.name")
  res := os.exec(program.install) or {
    panic("Error: $err")
  }
  println(res.output)
}

fn install(program Program, pacman string)  {
  println("[*] Installing $program.name")
  install := if pacman in program.install {
    program.install[pacman]
  } else {
    program.install['unknown']
  }
  res := os.exec(install) or {
    panic("Error: $err")
  }
  println(res.output)
}

fn prompt(question string) bool {
  for {
    response := os.input("$question (y/n) ")
    match response {
      'yes', 'y', 'yeah' { return true }
      'no', 'n', 'nope'  { return false }
      else {
        println("Please enter a valid response (y/n)")
      }
    }
  }
  return false
}

fn prompt_to_install(program Program) bool {
  return prompt("[?] Install $program.name?")
}

fn main()  {
  // Can't detect current user name for some reason
  if os.home_dir() == '/root' {
    eprintln("Please don't run me as root")
    exit(1)
  }
  mut cmd := Command{
    name: 'bootstraper'
    description: 'A simple CLI to bootstrap personal config'
    version: '1.0.0',
    execute: cli
  }

  cmd.add_flag(Flag {
    flag: .bool,
    name: 'auto',
    abbrev: 'a',
    description: 'Automatically install all programs'
  })
  cmd.parse(os.args)
}

fn cli(cmd Command) {
  println("Welcome to Andrew's system bootstrapping tool!")
  if !os.exists_in_system_path('doas') && !os.exists_in_system_path('sudo') {
    panic("Please install sudo/doas from your root user before continuing")
  }
  root := if os.exists_in_system_path('doas') { 'doas' } else { 'sudo '}

  println("Please install sudo or doas before continuing (doas recommended)")
  auto := cmd.flags.get_bool('auto') or {
    false
  }
  
  distro := detect_distro() or { 'unknown' }
  mut pacman := detect_pacman(distro)

  pacman_correct := prompt("[?] We've identified your package manager as '$pacman'. Is this correct?")
  if !pacman_correct {
    temp := os.input("[?] Then what is your package manger (newline for unknown/none)? ")
    if temp == '' {
      pacman = 'unknown'
    } else {
      pacman = temp
    }
  }

  // Arch users
  if pacman == 'pacman' && !os.exists_in_system_path('paru') {
    install_paru := prompt("[?] We've detected that you are an arch user (before you could tell use), would you like to install paru? (y/n)")
    if install_paru {
      simple_install(name: 'paru', install: 'sudo pacman -S paru')
    }
  }

  programs := [
    Program {
      name: 'zsh',
      install: {
        'unknown': 'echo "I could\'nt locate a universal install for zsh"',
        'pacman':  '$root pacman -S zsh',
        'yay': 		 'yay -S zsh',
        'paru': 	 'paru -S zsh'
        'apt': 		 '$root apt install zsh',
        'apk':     '$root apk add zsh',
      }
    },
    Program {
      name: 'volta',
      install: {
        'unknown': 'curl https://get.volta.sh | bash'
      },
      website: 'https://volta.sh/'
    },
    Program {
      name: 'rust',
      install: {
        'unknown': "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh",
        'pacman':  '$root pacman -S rustup',
        'yay': 		 'yay -S rustup',
        'paru': 	 'paru -S rustup'
      },
      website: 'https://rustup.sh'
    },
    Program {
      name: 'oh-my-zsh',
      install: {
        'unknown': 'sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"',
        'pacman':  '$root pacman -S oh-my-zsh',
        'yay':     'yay -S oh-my-zsh',
        'paru':    'paru -S oh-my-zsh',
      },
      website: 'https://ohmyz.sh'
    },
    Program {
      name: "starship",
      install: {
        'unknown': 'curl -fsSL https://starship.rs/install.sh | bash',
        'paru': 	 'paru -S starship-bin',
        'yay':     'yay -S starship-bin',
        'apk':     '$root apk add starship'
      },
      website: 'https://starship.rs'
    },
    // // Subprograms
    Program {
      name: 'node',
      install: {
        'unknown': 'volta install node'
      },
      website: 'https://nodejs.org'
    },
    // // Rust stuff
    Program {
      name: 'exa',
      install: {
        'unknown': 'cargo install exa',
        'pacman':  '$root pacman -S exa',
        'yay': 		 'yay -S exa',
        'paru': 	 'paru -S exa',
        'apt': 		 '$root apt install exa',
        'apk': 		 '$root apk add exa',
      },
      website: 'https://the.exa.website/'
    },
    Program {
      name: 'bat',
      install: {
        'unknown': 'cargo install bat',
        'pacman':  '$root pacman -S bat',
        'yay':     'yay -S bat',
        'paru':    'paru- S bat',
        'apt':     '$root apt install bat',
        'apk':     '$root apk add bat'
      },
      website: 'https://github.com/sharkdp/bat'
    },
    Program {
      name: 'neovim',
      install: {
        'unknown': 'echo "no universal install available for neovim"',
        'pacman':  '$root pacman -s neovim',
        'yay': 		 'yay -s neovim',
        'paru': 	 'paru- s neovim',
        'apt': 		 '$root apt install neovim',
        'apk': 		 '$root apk add neovim'
      },
    },
    Program {
      name: 'golang',
      install: {
        'unknown': 'echo "Install manually from https://golang.org/doc/install"',
        'pacman':  '$root pacman -s go',
        'yay': 		 'yay -s go',
        'paru': 	 'paru- s go',
        'apt': 		 '$root apt install golang',
        'apk': 		 '$root apk add go'
      },
    },
    Program {
      name: 'fd',
      install: {
        'unknown': 'cargo install fd-find',
        'pacman':  '$root pacman -S fd',
        'yay': 		 'yay -S fd',
        'paru': 	 'paru -S fd',
        'apt': 		 '$root apt install fd-find && echo \'alias fd="fd-find"\' >> ~/.zshrc',
        'apk':		 '$root apk add fd'
      }
    },
    Program {
      name: 'ripgrep',
      install: {
        'unknown': 'cargo install ripgrep',
        'pacman':  '$root pacman -S ripgrep',
        'yay':     'yay -S ripgrep',
        'paru':    'paru -S ripgrep',
        'apt':     '$root apt install ripgrep',
        'apk':     '$root apk add ripgrep'
      }
    },
    Program {
      name: 'vlang',
      install: {
        'unknown': 'git clone https://github.com/vlang/v && cd v && make'
      }
    },
    Program {
      name: 'bottom',
      install: {
        'unknown': 'cargo install bottom',
        'yay':     'yay -S bottom-bin',
        'paru':    'paru -S bottom-bin',
        'apt':     'curl -LO https://github.com/ClementTsang/bottom/releases/download/0.5.7/bottom_0.5.7_amd64.deb && $root dpkg -i bottom_0.5.7_amd64.deb'
      }
    }
  ]
  for program in programs {
    if auto {
      install(program, pacman)
    } else if prompt_to_install(program) {
      install(program, pacman)
    }
  }
}