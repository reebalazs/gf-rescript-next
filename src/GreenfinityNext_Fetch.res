open GreenfinityNext_Errors
open Belt

type method = [#get | #post | #put]

exception JsonDecodeError(string)

module FetchResponse = {
  type t = {
    ok: bool,
    status: int,
    arrayBuffer: (. unit) => Js.Promise2.t<Js.TypedArray2.ArrayBuffer.t>,
    text: (. unit) => Js.Promise2.t<string>,
    json: (. unit) => Js.Promise2.t<Js.Json.t>,
  }
  let jsonResult = async response => {
    let text = await response.text(.)
    try Js.Json.parseExn(text)->Result.Ok catch {
    | Js.Exn.Error(obj) =>
      switch Js.Exn.name(obj) {
      | Some("SyntaxError") => Result.Error(text)
      | Some(_) => raise(JsonDecodeError(obj->Js.Exn.message->Option.getWithDefault("")))
      | None => raise(JsonDecodeError(""))
      }
    | _ => Result.Error(text)
    }
  }
  let json = async response => await response.json(.)
}

@val external fetch: (string, {..}) => Js.Promise2.t<FetchResponse.t> = "fetch"

let fetchJson = (url: string, body: Js.Json.t) => {
  let options = {
    "method": #put,
    "headers": {
      "Content-Type": "application/json",
    },
    "body": body->Js.Json.stringify,
  }
  fetch(url, options)->Js.Promise2.then(res =>
    switch res.ok {
    | true => res.json(.)
    | false => raise(ApiError(res.status->apiErrorFromStatus))
    }
  )
}

let fetchJson0 = url => fetchJson(url, Js.Json.null)
