(* ::Package:: *)

BeginPackage["MPM`"];


  GitHubPacletInstall::usage = "
      GitHubPacletInstall[author, pacletName] installs paclet distributed via GitHub repository release

  ";



Begin["`Private`"];


  (*GitHubPacletInstall // Options = {
    Method \[Rule] Automatic
  };*)

  GitHubPacletInstall::noass = "Couldn't find assets for: ``/``";

  GitHubPacletInstall[author_String, paclet_String, version_String:"latest"]:=Module[
    {json, downloads, pacletAssetPattern}

  , pacletAssetPattern = KeyValuePattern["browser_download_url" -> url_String /; StringEndsQ[url, ".paclet"]]:>url

  ; Catch[
       json = Import[
           $ReleaseUrlTemplate[author, paclet, version]
         , "RawJSON"
       ]

     ; json // Print

     ; downloads = If[
           Not @ MatchQ[
               json
             , KeyValuePattern["assets" -> _List ? (MemberQ[First @ pacletAssetPattern])]
           ]

         , Message[GitHubPacletInstall::noass, paclet, version]
         ; Throw @ $Failed

         , Cases[json["assets"], pacletAssetPattern ]
       ]

     ; GitHubPacletInstall /@ downloads
   ]
  ];

  $ReleaseUrlTemplate = StringTemplate["https://api.github.com/repos/`1`/`2`/releases/`3`"]


(*      ; target = FileNameJoin[{CreateDirectory[], "paclet.paclet"}]
   ; If[
            $Notebooks
          , PrintTemporary @ Labeled[ProgressIndicator[Appearance -> "Necklace"]
              , "Downloading...", Right]
          , Print["Downloading..."]
        ]
      ; URLSave[download, target]
      , Return[$Failed]
    ]
  ; If[FileExistsQ[target], PacletInstall[target], $Failed]
]*)


End[];

EndPackage[];
