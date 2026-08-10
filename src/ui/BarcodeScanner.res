// Camera barcode scanner (ZXing). Interop-heavy and camera-dependent, so it
// cannot be verified headless — it needs real-device testing (the iOS-Safari
// spike ADR-0001 flags). Kept thin: it emits a barcode string; the lookup and
// logging live in testable ports/use-cases.

// Start scanning into `video`; call `onDetected` with the first decoded barcode.
// Returns a stop function. ZXing is dynamically imported so it is code-split
// out of the main bundle.
let startScan: (Dom.element, string => unit) => (unit => unit) = %raw(`
  (video, onDetected) => {
    let stopped = false;
    let controls = null;
    import("@zxing/browser").then(({ BrowserMultiFormatReader }) => {
      if (stopped) return;
      const reader = new BrowserMultiFormatReader();
      reader
        .decodeFromVideoDevice(undefined, video, (result, err, ctrls) => {
          controls = ctrls;
          if (result) { onDetected(result.getText()); ctrls.stop(); }
        })
        .then((c) => { controls = c; if (stopped) c.stop(); })
        .catch(() => {});
    });
    return () => { stopped = true; if (controls) controls.stop(); };
  }
`)

@react.component
let make = (~onDetected: string => unit, ~onClose: unit => unit) => {
  let videoRef = React.useRef(Nullable.null)

  React.useEffect0(() => {
    switch videoRef.current->Nullable.toOption {
    | Some(video) =>
      let stop = startScan(video, onDetected)
      Some(() => stop())
    | None => None
    }
  })

  <div className="scanner">
    <video
      ref={ReactDOM.Ref.domRef(videoRef)}
      className="scan-video"
      autoPlay=true
      muted=true
      playsInline=true
    />
    <p className="scan-hint"> {React.string("Point the camera at a barcode…")} </p>
    <button className="link" onClick={_ => onClose()}> {React.string("Cancel")} </button>
  </div>
}
