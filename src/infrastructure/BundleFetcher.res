// Fetches the open base bundle over HTTP and decompresses it (ADR-0006). Thin
// browser interop; the pure per-line decode is BundleDecoder. `decompressGzip`
// is factored out so the decompression path is testable headless.
type response
type readableStream
type transformStream

@val external fetch: string => promise<response> = "fetch"
@send external arrayBuffer: response => promise<'bytes> = "arrayBuffer"
@new external responseOfBytes: 'bytes => response = "Response"
@get external body: response => readableStream = "body"
@new external decompressionStream: string => transformStream = "DecompressionStream"
@send external pipeThrough: (readableStream, transformStream) => readableStream = "pipeThrough"
@new external responseOfStream: readableStream => response = "Response"
@send external text: response => promise<string> = "text"

// Decompress gzipped bytes to text via the web DecompressionStream.
let decompressGzip = async (bytes): string => {
  let stream = responseOfBytes(bytes)->body->pipeThrough(decompressionStream("gzip"))
  await responseOfStream(stream)->text
}

// A server may send the bundle with `Content-Encoding: gzip`, in which case the
// browser already decompressed the body. Detect the gzip magic bytes so we only
// decompress when the bytes are still compressed — robust to either serving mode.
let isGzip: 'buf => bool = %raw(`
  (buf) => { const a = new Uint8Array(buf); return a.length >= 2 && a[0] === 0x1f && a[1] === 0x8b; }
`)
let decodeText: 'buf => string = %raw(`(buf) => new TextDecoder().decode(buf)`)

// Fetch a `.ndjson.gz` bundle and return its NDJSON text.
let fetchBundle = async (url: string): string => {
  let response = await fetch(url)
  let bytes = await response->arrayBuffer
  isGzip(bytes) ? await decompressGzip(bytes) : decodeText(bytes)
}
