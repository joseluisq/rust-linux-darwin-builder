use openssl::aes::{unwrap_key, wrap_key, AesKey};

fn main() {
    let kek = b"\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F";
    let key_to_wrap = b"\x00\x11\x22\x33\x44\x55\x66\x77\x88\x99\xAA\xBB\xCC\xDD\xEE\xFF";

    let enc_key = AesKey::new_encrypt(kek).unwrap();
    let mut ciphertext = [0u8; 24];
    wrap_key(&enc_key, None, &mut ciphertext, &key_to_wrap[..]).unwrap();

    let dec_key = AesKey::new_decrypt(kek).unwrap();
    let mut orig_key = [0u8; 16];
    unwrap_key(&dec_key, None, &mut orig_key, &ciphertext[..]).unwrap();

    assert_eq!(&orig_key[..], &key_to_wrap[..]);

    println!("OpenSSL AES key wrapping tested sucessfully!")
}
