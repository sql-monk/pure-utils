 
    # Функція для виводу рядка з різними кольорами
    function Write-Banner {
        param(
            [Parameter(ValueFromPipeline)]
            [string]$Line,
            [string]$AccentColor = 'Cyan',
            [string]$BannerColor = 'DarkCyan'
        )
        
        process {
            $chars = $Line.ToCharArray()
            foreach ($char in $chars) {
                switch -Regex ($char) {
                    '█' { Write-Host $char -ForegroundColor $BannerColor -NoNewline }
                    '[║╚╝╔╗╠╣╦╩═─┌┐└┘├┤┬┴│]' { Write-Host $char -ForegroundColor DarkGray -NoNewline }
                    default { Write-Host $char -ForegroundColor $AccentColor -NoNewline }
                }
            }
            Write-Host ""
        }
    }
   
 
    function Write-PureUtilsBanner {
        param(
            [string]$AccentColor = 'Cyan',
            [string]$BannerColor = 'DarkCyan'
        )
        @(
            "",
            "    ██████╗ ██╗   ██╗██████╗ ███████╗",
            "    ██╔══██╗██║   ██║██╔══██╗██╔════╝",
            "    ██████╔╝██║   ██║██████╔╝█████╗  ",
            "    ██╔═══╝ ██║   ██║██╔══██╗██╔══╝  ",
            "    ██║     ╚██████╔╝██║  ██║███████╗",
            "    ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚══════╝",
            "                                      ",
            "    ██╗   ██╗████████╗██╗██╗     ███████╗",
            "    ██║   ██║╚══██╔══╝██║██║     ██╔════╝",
            "    ██║   ██║   ██║   ██║██║     ███████╗",
            "    ██║   ██║   ██║   ██║██║     ╚════██║",
            "    ╚██████╔╝   ██║   ██║███████╗███████║",
            "     ╚═════╝    ╚═╝   ╚═╝╚══════╝╚══════╝",
            "",
            "    ════════════════════════════════════════",
            "    https://github.com/sql-monk/pure-utils",
            "    ════════════════════════════════════════",
            ""

        ) | Write-Banner -AccentColor $AccentColor -BannerColor $BannerColor
    }

    function Write-SqlMonkBanner {
        param(
           
            [string]$BannerColor = 'DarkYellow'
        )
    @(
        "",
        "    ███████╗ ██████╗ ██╗     ███╗   ███╗ ██████╗ ███╗   ██╗██╗  ██╗",
        "    ██╔════╝██╔═══██╗██║     ████╗ ████║██╔═══██╗████╗  ██║██║ ██╔╝",
        "    ███████╗██║   ██║██║     ██╔████╔██║██║   ██║██╔██╗ ██║█████╔╝ ",
        "    ╚════██║██║▄▄ ██║██║     ██║╚██╔╝██║██║   ██║██║╚██╗██║██╔═██╗ ",
        "    ███████║╚██████╔╝███████╗██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║  ██╗",
        "    ╚══════╝ ╚══▀▀═╝ ╚══════╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝",
        ""
    ) | Write-Banner -BannerColor $BannerColor
    }