(* :Date: 2017-04-05 *)

(**)



  Needs @ "PacletManager`";



  Module[{newestRelease, localPaclet, needToFetch, releaseInfo, pacletURL, tempPath},
      Catch[

        releaseInfo = Check[
          ImportString[
            FromCharacterCode @ URLFetch[
              "https://api.github.com/repos/kubaPod/mpm/releases/latest"
            , "ContentData"
            ]
          , "JSON"
          ]
        , Throw @ $Failed
        ]

        ; newestRelease = StringTrim[Lookup[releaseInfo, "tag_name"], "v"];

        ; localPaclet = PacletFind @ "MPM";

        ; needToFetch = If[
              localPaclet === {}
            , True
            , PacletManager`Package`versionGreater[
                  newestRelease
                , localPaclet[[1]] @ "Version"
              ]
          ];

        ; If[
              Not @ needToFetch
            , Message[PacletInstall::samevers, "MPM", newestRelease]
            ; Check[Needs @ "MPM`", Throw @ $Failed]
            ; Throw @ True
          ]

        ; pacletURL = If[
            # === {}
          , Throw @ $Failed
          , First @ #
          ] &[
            Lookup[#, "browser_download_url", {}] & /@
              Lookup[releaseInfo, "assets", {}]
          ]

        ; tempPath = FileNameJoin[{$TemporaryDirectory, CreateUUID["MPM"] <> ".paclet"}]

        ; Check[ URLSave[pacletURL, tempPath], Throw @ $Failed]

        ; PacletInstall @ tempPath
      ]
  ]