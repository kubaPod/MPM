(* :Date: 2017-04-05 *)

(**)



  Needs @ "PacletManager`";



  Module[{newestRelease, localPaclet, needToFetch},
      Catch[
            (*not convenient but the fastest way to know what is the latest release*)
            (*keep this number in sync with the latest release NOT with the master branch paclet version*)
            (*the reason is that if not up to date we will install MPM from GH release assets*)
          newestRelease = "0.1.1";

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

        ; Import @ "https://raw.githubusercontent.com/kubapod/mpm/master/MPM/MPM.m"

        ; MPM`MPMInstall["kubapod", "MPM"]
      ]
  ]