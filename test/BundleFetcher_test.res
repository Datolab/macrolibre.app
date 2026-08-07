open Vitest

// Gzip a string to a Uint8Array using the web CompressionStream (node 22 has it).
let gzip: string => promise<'bytes> = %raw(`
  async (text) => {
    const stream = new Response(text).body.pipeThrough(new CompressionStream("gzip"));
    return new Uint8Array(await new Response(stream).arrayBuffer());
  }
`)

testAsync("decompresses gzipped bytes back to the original text", async () => {
  let bytes = await gzip("line one\nline two")
  let text = await BundleFetcher.decompressGzip(bytes)
  expect(text)->toBe("line one\nline two")
})

let plainBytes: string => 'buf = %raw(`(text) => new TextEncoder().encode(text).buffer`)

testAsync("detects gzip magic vs already-decompressed bytes", async () => {
  let gz = await gzip("hello")
  expect(BundleFetcher.isGzip(gz))->toBe(true)
  expect(BundleFetcher.isGzip(plainBytes("hello")))->toBe(false)
})
