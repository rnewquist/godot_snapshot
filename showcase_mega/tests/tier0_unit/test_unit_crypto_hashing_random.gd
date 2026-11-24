# test_unit_crypto_hashing_random.gd
# Tier 0 Pure Unit Suite: SHA-256, MD5, HashingContext, HMACContext, Crypto random generation, and RNG determinism.
extends "res://addons/gdtest/core/test_suite.gd"

func _init() -> void:
	suite_name = "Tier0_Unit_Crypto_Hashing_Random_Suite"
	test_type = "unit"

# 1. Crypto SHA-256 Buffer
func test_crypto_sha256_buffer() -> void:
	var text: String = "Hello World"
	var expected_hash: String = "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e"
	assert_eq(text.sha256_text(), expected_hash, "String sha256_text mismatch")
	var bytes: PackedByteArray = text.to_utf8_buffer()
	assert_eq(text.sha256_buffer().hex_encode(), expected_hash, "PackedByteArray sha256 buffer hex mismatch")

# 2. Crypto SHA-256 Streaming Context
func test_crypto_sha256_streaming_context() -> void:
	var ctx: HashingContext = HashingContext.new()
	var err: Error = ctx.start(HashingContext.HASH_SHA256)
	assert_eq(err, OK, "HashingContext start SHA256 must return OK")
	ctx.update("Hello ".to_utf8_buffer())
	ctx.update("World".to_utf8_buffer())
	var digest: PackedByteArray = ctx.finish()
	assert_eq(digest.hex_encode(), "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e", "Streamed SHA256 mismatch")

# 3. Crypto MD5 Buffer and String
func test_crypto_md5_buffer_and_string() -> void:
	var text: String = "Hello World"
	var expected_md5: String = "b10a8db164e0754105b7a99be72e3fe5"
	assert_eq(text.md5_text(), expected_md5, "String md5_text mismatch")
	var bytes: PackedByteArray = text.to_utf8_buffer()
	assert_eq(text.md5_buffer().hex_encode(), expected_md5, "PackedByteArray md5 buffer hex mismatch")

# 4. Crypto MD5 Streaming Context
func test_crypto_md5_streaming_context() -> void:
	var ctx: HashingContext = HashingContext.new()
	var err: Error = ctx.start(HashingContext.HASH_MD5)
	assert_eq(err, OK, "HashingContext start MD5 must return OK")
	ctx.update("Hello ".to_utf8_buffer())
	ctx.update("World".to_utf8_buffer())
	var digest: PackedByteArray = ctx.finish()
	assert_eq(digest.hex_encode(), "b10a8db164e0754105b7a99be72e3fe5", "Streamed MD5 mismatch")

# 5. Crypto HMAC-SHA256 Context
func test_crypto_hmac_sha256_context() -> void:
	var hmac: HMACContext = HMACContext.new()
	var key: PackedByteArray = "secret_key_123".to_utf8_buffer()
	var err: Error = hmac.start(HashingContext.HASH_SHA256, key)
	assert_eq(err, OK, "HMACContext start must return OK")
	hmac.update("payload_data".to_utf8_buffer())
	var digest: PackedByteArray = hmac.finish()
	assert_eq(digest.size(), 32, "HMAC-SHA256 digest size must be 32 bytes")
	assert_not_empty(digest.hex_encode(), "HMAC digest must not be empty")

# 6. Crypto HMAC Key and Data Specificity
func test_crypto_hmac_key_and_data_specificity() -> void:
	var hmac1: HMACContext = HMACContext.new()
	hmac1.start(HashingContext.HASH_SHA256, "key_A".to_utf8_buffer())
	hmac1.update("common_data".to_utf8_buffer())
	var digest1: PackedByteArray = hmac1.finish()
	
	var hmac2: HMACContext = HMACContext.new()
	hmac2.start(HashingContext.HASH_SHA256, "key_B".to_utf8_buffer())
	hmac2.update("common_data".to_utf8_buffer())
	var digest2: PackedByteArray = hmac2.finish()
	
	assert_ne(digest1, digest2, "Different HMAC keys must yield different digests")

# 7. Crypto Generate Random Bytes
func test_crypto_generate_random_bytes() -> void:
	var crypto: Crypto = Crypto.new()
	var rand_bytes: PackedByteArray = crypto.generate_random_bytes(32)
	assert_eq(rand_bytes.size(), 32, "Random byte count mismatch")
	var is_non_zero: bool = false
	for b in rand_bytes:
		if b != 0:
			is_non_zero = true
			break
	assert_true(is_non_zero, "Random bytes must contain non-zero entropy")

# 8. Crypto Random Bytes Entropy
func test_crypto_random_bytes_entropy() -> void:
	var crypto: Crypto = Crypto.new()
	var buf1: PackedByteArray = crypto.generate_random_bytes(32)
	var buf2: PackedByteArray = crypto.generate_random_bytes(32)
	assert_ne(buf1, buf2, "Subsequent random byte generation must yield distinct entropy")

# 9. RNG Seed Determinism
func test_random_number_generator_seed_determinism() -> void:
	var rng1: RandomNumberGenerator = RandomNumberGenerator.new()
	var rng2: RandomNumberGenerator = RandomNumberGenerator.new()
	rng1.seed = 987654321
	rng2.seed = 987654321
	for i in range(10):
		var r1: int = rng1.randi()
		var r2: int = rng2.randi()
		assert_eq(r1, r2, "Identically seeded RNGs must produce identical stream")

# 10. RNG State Save & Restore
func test_random_number_generator_state_save_restore() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(5):
		rng.randi()
	var saved_state: int = rng.state
	
	var seq_a: Array[int] = []
	for i in range(5):
		seq_a.append(rng.randi())
		
	rng.state = saved_state
	var seq_b: Array[int] = []
	for i in range(5):
		seq_b.append(rng.randi())
		
	assert_array_eq(seq_a, seq_b, "Restoring RNG state must reproduce identical sequence")

# 11. RNG Range Bounds
func test_random_number_generator_range_bounds() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 10101
	for i in range(100):
		var val_f: float = rng.randf_range(10.0, 20.0)
		assert_in_range(val_f, 10.0, 20.0, "randf_range must remain within [10.0, 20.0]")
		var val_i: int = rng.randi_range(1, 6)
		assert_true(val_i >= 1 and val_i <= 6, "randi_range must remain within [1, 6]")

# 12. RNG Randfn Distribution
func test_random_number_generator_randfn_distribution() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 55555
	var sum: float = 0.0
	var count: int = 500
	for i in range(count):
		sum += rng.randfn(100.0, 10.0)
	var mean: float = sum / float(count)
	assert_in_range(mean, 98.0, 102.0, "Sample mean of normal distribution with mean 100 must be within [98, 102]")
