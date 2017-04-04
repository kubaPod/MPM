(* ::Package:: *)

BeginPackage["MPM`"];

  Needs @ "PacletManager`";

  MPMInstall;


Begin["`Private`"];

  MPMInstall // Options = {
      "Method" -> Automatic
    , "Logger" -> Automatic
    (*, "Destination" -> Automatic*)


  };

  MPMInstall::noass = "Couldn't find assets for: ``/``";
  MPMInstall::invmeth = "Unknown method ``";


  MPMInstall::assetsearch = "searching for assets `1`/`2`/`3`";
  MPMInstall::dload = "downloading ``...";
  MPMInstall::inst = "installing ``...";



  MPMInstall[args__, patt:OptionsPattern[]]:= Module[{ method = OptionValue["Method"] }
    , Block[
        {$logger = OptionValue["Logger"] /. Automatic -> $DefaultLogger}

        , Switch[ method
            , Automatic | "GitHubAssets"
            , GitHubPacletInstall[args, patt]

            , _
            , Message[MPMInstall::invmeth, method]; $Failed
          ]
      ]
  ];

  $logger;
  $DefaultLogger = PrintTemporary;


  $ReleaseUrlTemplate = StringTemplate["https://api.github.com/repos/`1`/`2`/releases/`3`"];

  $PacletAssetPattern = KeyValuePattern[
    "browser_download_url" -> url_String /; StringEndsQ[url, ".paclet"]
  ] :> url;



  GitHubPacletInstall::usage = "
        GitHubPacletInstall[author, pacletName] installs paclet distributed via GitHub repository release

    ";

  GitHubPacletInstall // Options = Options @ MPMInstall;


  (*TODO: if version is not 'latest' check if it isn't already installed*)
  (*TODO: consider adding 'Force' option that will force overwriting instead of asking user*)
  (*TODO: add conditional progress indicator, based on $Notebooks and $logger wrapper*)

  GitHubPacletInstall[author_String, paclet_String, version_String:"latest", patt:OptionsPattern[]]:=Module[
      {json, downloads}



    , Catch[

          $logger @ StringTemplate[MPMInstall::assetsearch][  author, paclet, version ]

        ; json = Import[
              $ReleaseUrlTemplate[author, paclet, version]
            , "RawJSON"
          ]


        ; downloads = If[
             Not @ MatchQ[
                 json
               , KeyValuePattern["assets" -> _List ? (MemberQ[First @ $PacletAssetPattern])]
             ]

           , Message[MPMInstall::noass, paclet, version]
           ; Throw @ $Failed

           , Cases[json["assets"], $PacletAssetPattern ]
         ]

       ; If[
             Length @ downloads > 1
           , GitHubPacletInstall /@ downloads
           , GitHubPacletInstall @ First @ downloads
         ]
     ]
  ];

  GitHubPacletInstall[
      url_String
    , OptionsPattern[]
  ] /; StringMatchQ[url, "ftp"|"http"~~__~~".paclet"]:= Module[
      {temp}
    , temp = FileNameJoin[{$TemporaryDirectory, CreateUUID[] <> ".paclet"}]

    (*TODO: check existence up front*)
    ;  Catch[
           $logger @ StringTemplate[MPMInstall::dload] @ FileNameTake[url]

         ; URLSave[url, temp]

         ; If[
               FileExistsQ @ temp
             , $logger @ StringTemplate[MPMInstall::inst] @ FileNameTake[url]
             ; PacletInstall @ temp

             , Throw @ $Failed
           ]
       ]


  ];




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
