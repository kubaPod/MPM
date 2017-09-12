(* ::Package:: *)

System`MPM::insv = "MPM only supports Mathematica `` or later.";

If[
    $VersionNumber < #
  , Message[System`MPM::insv, #]
  ; Abort[]
]&[10.4]


(* ::Section:: *)
(*Begin*)


BeginPackage["MPM`"];

  Needs @ "PacletManager`";

  MPMInstall;

  WithPacletRepository;

Begin["`Private`"];


(* ::Section:: *)
(*Content*)


(* ::Subsubsection::Closed:: *)
(*misc*)


(*TODO: check whether the paclet can be found after it is installed.
  If it is not, inform user that it probably doesn't meet requirements*)

  $DefaultLogger = Print;


(* ::Subsection:: *)
(*MPMInstall*)


(* ::Subsubsection::Closed:: *)
(*options*)


  MPMInstall // Options = {
        "Method"              -> Automatic
      , "Logger"              -> Automatic
      , "Destination"         -> Automatic
      , "ConfirmRequirements" -> True
  };


(* ::Subsubsection::Closed:: *)
(*messages*)


  MPMInstall::noass       = "Couldn't find assets for: ``/``";
  MPMInstall::invmeth     = "Unknown method ``";
  MPMInstall::insreq      = "Paclet `1`-`2` was installed but can't be foud. Check requirements:\n`3`";
  MPMInstall::assetsearch = "Searching for assets `1`/`2`/`3`";
  MPMInstall::dload       = "Downloading ``...";
  MPMInstall::inst        = "Installing ``...";


(* ::Subsubsection:: *)
(*Install method switch*)


  MPMInstall[
      args__
    , patt : OptionsPattern[{MPMInstall, PacletInstall}]

  ]:= Module[ { method = OptionValue["Method"] }

    , Switch[ method
        , Automatic | "gh-assets-paclet"
        , GitHubAssetInstall[args, patt]

        , _
        , Message[MPMInstall::invmeth, method]; $Failed
      ]

  ];


(* ::Subsubsection::Closed:: *)
(*Install from url*)


    (*TODO: once PacletInstall supports https it will probably go*)
  MPMInstall[
      url_String /; StringMatchQ[url, "http"|"ftp"~~__~~".paclet"]
    , patt : OptionsPattern[{MPMInstall, PacletInstall}]

  ]:= Module[
      { temp
      , logger          = OptionValue["Logger"] /. Automatic -> $DefaultLogger
      , pacletFileName  = FileNameTake @ url
      }

    , temp = FileNameJoin[{$TemporaryDirectory, CreateUUID[] <> ".paclet"}]

         (*TODO: check existence up front*)
    ;  Catch[
           logger @ StringTemplate[MPMInstall::dload] @ pacletFileName

         ; URLSave[url, temp]

         ; If[
               FileExistsQ @ temp
             , MPMInstall[ temp, patt, "PacletFileName" -> pacletFileName ]
             , Throw @ $Failed
           ]
       ]


  ];


(* ::Subsubsection::Closed:: *)
(*Install from file*)


    (*the final step*)
  MPMInstall[

      pacletPath_String ? FileExistsQ /; StringEndsQ[pacletPath, ".paclet"]
    , patt : OptionsPattern[{MPMInstall, PacletInstall, "PacletFileName" -> Automatic}]

  ]:= Module[

      { $logger     = OptionValue["Logger"] /. Automatic -> $DefaultLogger
      , repo        = OptionValue["Destination"]
      , options     = FilterRules[{patt}, Options[PacletInstall]]
      , pacletName  = OptionValue["PacletFileName"] /. Automatic -> FileNameTake @ pacletPath
      , confirm     = OptionValue["ConfirmRequirements"]
      , paclet, found
      }

    , $logger @ StringTemplate[MPMInstall::inst] @ pacletName

    ; Catch[

          paclet = WithPacletRepository[repo] @ PacletInstall[pacletPath, options]

        ; Which[
              FailureQ @ paclet , Throw @ paclet
            , Not @ confirm, Throw @ paclet
          ]

        ; repo =   (repo /. {
              Automatic -> All
            , dir_String?DirectoryQ :> PacletRepository[dir]
          })

        ; found = PacletFind[
              paclet @ "Name"
            , "Location" -> repo
          ]

        ; If[
              Not @ MemberQ[found, paclet]
            , Message[MPMInstall::insreq, insReqArguments @ paclet]
          ]

        ; paclet



      ]

  ];

    insReqArguments[ paclet_ ]:= Sequence[
        paclet @ "Name"
      , paclet @  "Version"
      , paclet // requirementsString
    ];

    requirementsString = ExportString[
      List @@@ Normal @ KeyTake[
          {"Qualifier", "WolframVersion", "SystemID", "MathematicaVersion"}
      ] @ PacletInformation[#]
      ,
      "Table"
    ]&;




(* ::Subsection:: *)
(*Paclets Utilities*)


(* ::Subsubsection:: *)
(*WithPacletRepository*)


    (*Haven't found a trace of any option designed for this so we are using this helper function
      to install paclet is desired directory.
      One should expect that the option IgnoreVersion -> True should be added too in order to
      ignore available paclets during installation/copying a specific paclet to e.g. dependencies
    *)

  WithPacletRepository::usage = "WithPacletRepository[dir][proc] creates environment for proc such that "<>
      "the PacletManager assumes dir to be user paclets' repository directory. "<>
      "The main purpose is to use with PacletInstall so that the paclet is installed "<>
      "e.g. in dependencies folder of another project.";

  WithPacletRepository[dir_String?DirectoryQ] := Function[
      expr
    , Block[{ PacletManager`Package`$userRepositoryDir = dir }
        , expr
      ]
    , HoldFirst
  ];

  WithPacletRepository[Automatic] = Identity;





(* ::Subsubsection::Closed:: *)
(*PacletRepository*)


    (*In future we need to know whether desired paclets are in a specific directory regardless
      whether they are in others. PacletFind "Location" checks only for the paclet directory
      and can't understand paclet parent directory. It also checks with SameQ :( this wrapper should help

    So if you have MyPaclet installed in paclets/repository/folder you can confimr that with:

    PacletFind["MyPaclet", "Location" -> PacletRepository["paclets/repository/folder"]]

    otherwise one would have to use paclets/repository/folder/MyPalcet, which makes it pretty useless
    unless we want to confirm a specific paclet is exactly where we expect it*)

  PacletRepository::usage = "Symbolic wrapper for directory used as PacletFind's location.";
  PacletRepository // ClearAll;
  PacletRepository /: SameQ[pacletDir_, PacletRepository[dir_]] := StringMatchQ[
    pacletDir, dir ~~ __
  ];



(* ::Subsection:: *)
(*Specific installations*)


(* ::Subsubsection:: *)
(*GitHubAssetInstall*)


  GitHubAssetInstall::usage = "
          GitHubAssetInstall[author, pacletName] installs paclet distributed via GitHub repository release

      ";

  GitHubAssetInstall // Options = Options @ MPMInstall;


  (*TODO: if version is not 'latest' check if it isn't already installed*)
  (*TODO: consider adding 'Force' option that will force overwriting instead of asking user*)
  (*TODO: add conditional progress indicator, based on $Notebooks and $logger wrapper*)

  GitHubAssetInstall[
      author_String
    , paclet_String
    , version_String:"latest"
    , patt : OptionsPattern[{GitHubAssetInstall, PacletInstall}]

  ]:=Module[
      { json
      , downloads
      , pacletInstall
      , $logger = OptionValue["Logger"] /. Automatic -> $DefaultLogger
      }

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
            Length @ downloads == 1
          , MPMInstall[First @ downloads, patt]
          , MPMInstall[#, patt]& /@ downloads

        ]
    ]
  ];




  $ReleaseUrlTemplate = StringTemplate[
    "https://api.github.com/repos/`1`/`2`/releases/<* If[#3=!=\"latest\", \"tags/\", \"\"] *>`3`"
  ];

  $PacletAssetPattern = KeyValuePattern[
    "browser_download_url" -> url_String /; StringEndsQ[url, ".paclet"]
  ] :> url;



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


(* ::Section:: *)
(*End*)


End[];

EndPackage[];
