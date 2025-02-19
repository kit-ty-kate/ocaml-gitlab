let ( / ) = Filename.concat

let read_ic ic =
  let rec loop prev =
    match try Some (input_line ic) with End_of_file -> None with
    | Some line -> loop (line :: prev)
    | None -> List.rev prev
  in
  String.concat "\n" (loop [])

let read_file path =
  let ic = open_in path in
  let contents = read_ic ic in
  close_in ic;
  contents

let yojson =
  let module M = struct
    type t = Yojson.Basic.t

    let pp f t = Fmt.pf f "%s" (Yojson.Basic.pretty_to_string t)

    let equal = Yojson.Basic.equal
  end in
  (module M : Alcotest.TESTABLE with type t = M.t)

module type TestableJson = sig
  type t

  val name : string (* directory for serialisation example *)

  val of_string : string -> t

  val to_json : t -> Yojson.Basic.t
end

module Make (M : TestableJson) = struct
  let test () =
    let open Alcotest in
    let base = "cases" / M.name in
    let test_file = read_file (base / "event.json") in
    let diff_json output =
      let expected =
        M.to_json @@ M.of_string @@ read_file (base / "expected.json")
      in
      Alcotest.(check yojson) "diff-json" expected output
    in
    let a =
      try M.of_string test_file
      with e ->
        Alcotest.fail (M.name ^ " failed with: " ^ Printexc.to_string e)
    in
    [ test_case M.name `Quick (fun () -> diff_json (M.to_json a)) ]
end

module Gitlab_j_events : TestableJson = struct
  type t = Gitlab_j.events

  let name = "events"

  let of_string = Gitlab_j.events_of_string

  let to_json v = Yojson.Basic.from_string (Gitlab_j.string_of_events v)
end

module Gitlab_j_user_short : TestableJson = struct
  type t = Gitlab_j.user_short

  let name = "user_short"

  let of_string = Gitlab_j.user_short_of_string

  let to_json v = Yojson.Basic.from_string (Gitlab_j.string_of_user_short v)
end

module Gitlab_j_projects : TestableJson = struct
  type t = Gitlab_j.projects_full

  let name = "projects"

  let of_string = Gitlab_j.projects_full_of_string

  let to_json v = Yojson.Basic.from_string (Gitlab_j.string_of_projects_full v)
end

module Gitlab_j_project_short : TestableJson = struct
  type t = Gitlab_j.project_short

  let name = "project_short"

  let of_string = Gitlab_j.project_short_of_string

  let to_json v = Yojson.Basic.from_string (Gitlab_j.string_of_project_short v)
end

module Gitlab_j_webhooks : TestableJson = struct
  type t = Gitlab_j.webhooks

  let name = "webhooks"

  let of_string = Gitlab_j.webhooks_of_string

  let to_json v = Yojson.Basic.from_string (Gitlab_j.string_of_webhooks v)
end

module Gitlab_j_merge_requests : TestableJson = struct
  type t = Gitlab_j.merge_requests

  let name = "merge_requests"

  let of_string = Gitlab_j.merge_requests_of_string

  let to_json v = Yojson.Basic.from_string (Gitlab_j.string_of_merge_requests v)
end

module Gitlab_j_commit_statuses : TestableJson = struct
  type t = Gitlab_j.commit_statuses

  let name = "commit_statuses"

  let of_string = Gitlab_j.commit_statuses_of_string

  let to_json v =
    Yojson.Basic.from_string (Gitlab_j.string_of_commit_statuses v)
end

module Gitlab_j_branches_full : TestableJson = struct
  type t = Gitlab_j.branches_full

  let name = "branches"

  let of_string = Gitlab_j.branches_full_of_string

  let to_json v = Yojson.Basic.from_string (Gitlab_j.string_of_branches_full v)
end

module Gitlab_j_milestones : TestableJson = struct
  type t = Gitlab_j.milestones

  let name = "milestones"

  let of_string = Gitlab_j.milestones_of_string

  let to_json v = Yojson.Basic.from_string (Gitlab_j.string_of_milestones v)
end

(* instances under test *)
module E = Make (Gitlab_j_events)
module US = Make (Gitlab_j_user_short)
module P = Make (Gitlab_j_projects)
module PS = Make (Gitlab_j_project_short)
module WH = Make (Gitlab_j_webhooks)
module MR = Make (Gitlab_j_merge_requests)
module CS = Make (Gitlab_j_commit_statuses)
module BF = Make (Gitlab_j_branches_full)
module M = Make (Gitlab_j_milestones)

(* Run it *)
let () =
  let open Alcotest in
  run "GitLab"
    [
      ("commit_statuses", CS.test ());
      ("events", E.test ());
      ("merge_requests", MR.test ());
      ("project_short", PS.test ());
      ("projects", P.test ());
      ("user_short", US.test ());
      ("webhooks", WH.test ());
      ("branches", BF.test ());
      ("milestones", M.test ());
    ]
