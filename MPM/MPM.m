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
(*settings*)


(*TODO: check whether the paclet can be found after it is installed.
  If it is not, inform user that it probably doesn't meet requirements*)

  $DefaultLogger = Print;


(* ::Subsubsection:: *)
(*utilities*)



   (* https://mathematica.stackexchange.com/a/55746/5478 *)
toAssociation = Replace[#,a:{__Rule}:>Association[a],{0,\[Infinity]}]&;

   (* https://mathematica.stackexchange.com/q/154245/5478 *)
bytesToAssociation[bytes:{__Integer}]:= toAssociation @ ImportString[FromCharacterCode[bytes], "JSON"]
bytesToAssociation[___]=$Failed;


MPMInstall::fetchIssue = "Call to `` returned `` \n\n\t ``";
MPMInstall::fetchFailed = "Call to `` failed."
urlExecute[p_, r___]:= Module[{response}
, response = URLFetch[p, {"StatusCode", "ContentData"}]

; Switch[ 
      response
    , {200, {__Integer}}
    , bytestToAssociation @ Last @ response
    
    , {_Integer, {__Integer}}
    , Message[MPMInstall::fetchIssue, p, response[[1]], FromCharacterCode @ response[[2]]]
    ; $Failed
    
    , _
    , Message[MPMInstall::fetchFailed, p]
    ; $Failed
  ]
];
  (*fetch stuff and return association assuming it is json*)


(* ::Subsection:: *)
(*MPMInstall*)


(* ::Subsubsection:: *)
(*options*)


  (*not all options will be relevant for all repositories*)
  
  MPMInstall // Options = {
        "Source"              -> Automatic
      , "Logger"              -> Automatic
      , "Destination"         -> Automatic
      , "ConfirmRequirements" -> True
      , "AllowDrafts"         -> False (*whether to honor draft releases*)
      , "AllowPrereleases"    -> False (*whether to honor prereleases*)
      , "Credentials"         -> {} (*_String is considered a token, {_, _} is considered username/pw*)
      , "Release"             -> "latest"
  };


(* ::Subsubsection::Closed:: *)
(*messages*)


  MPMInstall::noass       = "Couldn't find assets for: ``/``";
  MPMInstall::invst     = "Unknown source type: ``";
  MPMInstall::insreq      = "Paclet `1`-`2` was installed but can't be foud. Check requirements:\n`3`";
  MPMInstall::assetsearch = "Searching for assets `1`/`2`/`3`";
  MPMInstall::dload       = "Downloading ``...";
  MPMInstall::inst        = "Installing ``...";


(* ::Subsubsection::Closed:: *)
(*Install source switch*)


  MPMInstall[
      args__
    , patt : OptionsPattern[{MPMInstall, PacletInstall}]

  ]:= Module[ { type = OptionValue["Source"] }

    , Switch[ type
        , Automatic | "gh-assets-paclet"
        , GitHubAssetInstall[args, patt]

        , _
        , Message[MPMInstall::invst, type]; $Failed
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


(* ::Subsubsection::Closed:: *)
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

    So if you have e.g. MyPaclet installed in paclets/repository/folder you can confimr that with:

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


(* ::Subsubsubsection:: *)
(*GitHubAssetInstall*)


  GitHubAssetInstall::usage = "GitHubAssetInstall[author, pacletName] installs paclet distributed via GitHub repository release";

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
      { json, spec
      , downloads
      , pacletInstall
      , $logger = OptionValue["Logger"] /. Automatic -> $DefaultLogger
      }

    , Catch[

          $logger @ StringTemplate[MPMInstall::assetsearch][  author, paclet, version ]

        ; spec = <|
            "paclet" -> paclet
          , "author" -> author
          , "version" -> version
          , Options @ GitHubAssetInstall
          , "logger" -> $logger
          , patt
          |>
          
        ; downloads = If[ withDrafts || withPre
            , assetsPacletsFind @ spec
            , assetsPacletsFindBasic @ spec
          ]
   
        ; json = bytesToAssociation @ URLFetch[
            $ReleaseUrlTemplate[author, paclet, version]
          , "ContentData"
          ]
              
        ; downloads = Select[
            json[["assets", All, "browser_download_url"]]
          , StringMatchQ[#, __~~".paclet"]&
          ]

        ; If[
            Length @ downloads
          , Message[MPMInstall::noass, paclet, version]
          ; Throw @ $Failed
       
        ]

        ; If[
            Length @ downloads == 1
          , MPMInstall[First @ downloads, patt]
          , MPMInstall[#, patt]& /@ downloads

        ]
    ]
  ];




(* ::Subsubsubsection:: *)
(*fetch latest links*)


assetsPacletsFindBasic[spec_Association]:= Module[{}
, Catch[

  ]
];

assetsPacletsFindBasic[___]=$Failed;


(* ::Subsubsubsection::Closed:: *)
(*misc*)


  $ReleaseUrlTemplate = StringTemplate[
    "https://api.github.com/repos/`1`/`2`/releases/<* If[#3=!=\"latest\", \"tags/\", \"\"] *>`3`"
  ];
(*
  $PacletAssetPattern = KeyValuePattern[
    "browser_download_url" -> url_String /; StringEndsQ[url, ".paclet"]
  ] :> url;
*)


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
