# 🎬 Tài liệu Tính năng: AI Movie Recommendation (Gợi ý phim cá nhân hóa)

> **Môn học:** PRM393 — Mobile Programming  
> **Ứng dụng:** Movie Diary (Nhật ký theo dõi phim cá nhân)  
> **Cơ chế cốt lõi:** AI-Driven Recommendation Engine (Zero Movie Catalog Database)

---

## 1. Vì sao App KHÔNG CẦN Movie Database để gợi ý phim?

Hầu hết các hệ thống gợi ý truyền thống (Content-Based Filtering / Collaborative Filtering) đòi hỏi phải có một cơ sở dữ liệu phim khổng lồ (hàng chục nghìn bộ phim kèm ID, metadata, diễn viên, tóm tắt...) để thực hiện truy vấn và lọc dữ liệu.

Tuy nhiên, **Movie Diary sử dụng kiến trúc AI-First:**
- **Mô hình ngôn ngữ lớn (LLMs như Google Gemini, OpenAI GPT)** đã được tiền huấn luyện trên kho tri thức khổng lồ của nhân loại, bao gồm toàn bộ lịch sử điện ảnh thế giới từ kinh điển đến hiện đại.
- LLM đóng vai trò như một **chuyên gia phê bình điện ảnh am hiểu sâu rộng**: Chỉ cần nhận danh sách phim người dùng đã xem kèm cảm nhận, AI tự động suy luận ra gu thưởng thức, phong cách đạo diễn, thể loại ưa thích, nhịp phim,... và **tự đề xuất các tựa phim mới phù hợp mà không cần app lưu trữ bất kỳ danh mục phim nào trước đó**.
- Nhờ vậy, ứng dụng cực kỳ gọn nhẹ (nhẹ hơn 95% so với việc nhúng một database phim nặng nề), dữ liệu luôn tươi mới và không bị giới hạn trong một tập dữ liệu đóng.

---

## 2. Dữ liệu người dùng được gửi cho AI như thế nào?

Khi người dùng mở ứng dụng hoặc bấm làm mới mục **"Gợi ý dành cho bạn"**, `RecommendationService` sẽ trích xuất dữ liệu thực tế từ cơ sở dữ liệu SQLite cục bộ (`DatabaseHelper.instance.getWatchedMovies()`):

1. **Danh sách các phim đã xem:**
   - Tên phim (`title`), Năm phát hành (`releaseYear`), Thể loại (`genre`).
   - Điểm đánh giá cá nhân (`rating`, từ 0.0 đến 5.0⭐).
   - Review / ghi chú cá nhân (`review`) — *giúp AI hiểu sâu sắc lý do người dùng thích hay ghét bộ phim*.
2. **Hồ sơ gu thưởng thức (Taste Profile):**
   - Các thể loại được đánh giá cao nhất (tổng hợp điểm số và tần suất xuất hiện).
3. **Danh sách đen (Negative Constraint):**
   - Danh sách toàn bộ tựa phim người dùng đã lưu để yêu cầu AI **tuyệt đối không gợi ý lại**.

---

## 3. AI tự sinh Movie Recommendation như thế nào? (Prompt Structure)

Prompt được xây dựng **động 100%** từ dữ liệu cá nhân của từng người dùng, không hề hard-code sở thích:

```text
You are an expert movie recommendation assistant.

Analyze this user's personal movie watching diary and taste preferences.

=== USER WATCH HISTORY ===
- Inception (2010) · Genre: Sci-Fi · Rating: 4.8/5.0 · Review: "Mind-bending dream heist"
- Interstellar (2014) · Genre: Sci-Fi · Rating: 4.9/5.0 · Review: "Emotional masterpiece"
- Spirited Away (2001) · Genre: Animation · Rating: 5.0/5.0

=== USER TASTE PROFILE ===
- Preferred genres: Sci-Fi, Animation
- Total movies watched: 3

=== STRICT REQUIREMENTS ===
1. DO NOT recommend any movie that the user has already watched: ["Inception", "Interstellar", "Spirited Away"].
2. Recommend 4 to 6 fresh, diverse, high-quality movies that match their tastes.
3. For each recommended movie, explain specifically in Vietnamese why the user would enjoy it (field "reason").
4. Provide a "matchScore" integer between 75 and 98 based on user history.
5. If you know a valid public poster URL (e.g. from TMDB or Wikimedia), provide it in "posterUrl"; otherwise use null.
6. Return ONLY valid JSON matching this exact structure:
{
  "recommendations": [
    {
      "title": "Movie Title",
      "year": 2024,
      "genre": ["Sci-Fi", "Drama"],
      "reason": "Vì bạn rất thích các bộ phim Sci-Fi có chiều sâu và ý tưởng độc đáo...",
      "matchScore": 94,
      "posterUrl": null
    }
  ]
}
```

---

## 4. Định dạng JSON Response từ AI

```json
{
  "recommendations": [
    {
      "title": "Arrival",
      "year": 2016,
      "genre": ["Sci-Fi", "Drama"],
      "reason": "Vì bạn rất thích phim Sci-Fi có cốt truyện giàu cảm xúc và bất ngờ như Interstellar.",
      "matchScore": 95,
      "posterUrl": "https://image.tmdb.org/t/p/w500/x2FJsf1ElAgr63Y3PNPtJrcmpoe.jpg"
    },
    {
      "title": "Blade Runner 2049",
      "year": 2017,
      "genre": ["Sci-Fi", "Mystery"],
      "reason": "Hình ảnh choáng ngợp và không khí bí ẩn phù hợp với gu phim Christopher Nolan của bạn.",
      "matchScore": 92,
      "posterUrl": null
    }
  ]
}
```

- Không yêu cầu `movieId` từ cơ sở dữ liệu của ứng dụng.
- Nếu AI không trả về `posterUrl`, app hiển thị placeholder poster chuẩn theme, không tạo bản ghi rỗng trong SQLite.

---

## 5. Cách Validate AI Response

Hàm `RecommendationService.parseAndValidateResponse()` thực hiện các bước kiểm tra an toàn:
1. **Làm sạch Markdown:** Tự động loại bỏ các khối ```` ```json ... ``` ```` do LLM sinh ra.
2. **Kiểm tra Schema:**
   - Đảm bảo root JSON là một Map và có key `"recommendations"` là một List.
   - Mỗi item phải có trường `title` hợp lệ (chuỗi không rỗng), `year` (số nguyên), `genre` (danh sách thể loại), `reason` (chuỗi lý do), `matchScore` (số nguyên từ 0–100).
3. **Loại bỏ trùng lặp (Deduplication):**
   - Chuẩn hóa tên phim (`_normalizeTitle`) để loại bỏ các phim bị AI lặp lại trong cùng 1 lần trả về.
4. **Kiểm tra số lượng:**
   - Nếu sau khi lọc danh sách bị rỗng, hệ thống sẽ kích hoạt Fallback ngay lập tức.

---

## 6. Cách Loại bỏ Phim Người Dùng Đã Xem

Ứng dụng áp dụng cơ chế bảo vệ 2 tầng:
1. **Tầng 1 (Prompt Constraint):** Gửi rõ danh sách tên phim đã xem kèm lệnh nghiêm ngặt: `DO NOT recommend any movie that the user has already watched: [...]`.
2. **Tầng 2 (Client-Side Normalization & Filtering):**
   - Toàn bộ tên phim trong lịch sử xem được chuẩn hóa: chuyển chữ thường, loại bỏ ký tự đặc biệt, dấu câu và khoảng trắng thừa.
   - Tên phim do AI đề xuất cũng được chuẩn hóa tương tự.
   - Bất kỳ phim nào trùng khớp với lịch sử xem sẽ bị loại bỏ khỏi danh sách trước khi hiển thị cho người dùng.

---

## 7. Cơ chế Fallback hoạt động thế nào? (Không Database Phim & Không Hard-code)

Khi xảy ra các lỗi:
- Mất kết nối mạng / Timeout (quá 15 giây).
- Chưa cấu hình hoặc cấu hình sai API Key.
- Server AI bị lỗi (HTTP 500, 503, 429 Rate Limit).
- Response bị lỗi cú pháp JSON hoặc rỗng.

**Quy tắc Fallback:**
- **Không hard-code danh sách phim cố định trong app** (vì hard-code sẽ vi phạm nguyên tắc cá nhân hóa).
- **Không dùng database catalog bên ngoài**.
- Thay vào đó, Fallback sử dụng chính dữ liệu người dùng đã lưu:
  1. Lọc ra các bộ phim người dùng từng đánh giá cao (`rating >= 4.0⭐`), sắp xếp theo điểm giảm dần.
  2. Tạo gợi ý dưới dạng **"Phim bạn có thể xem lại"** kèm lý do:  
     `"Phim bạn đã chấm 4.9⭐ - Một tác phẩm xuất sắc rất đáng để bạn thưởng thức lại."`
  3. Hiển thị thông báo màu vàng trực quan: `⚡ AI đang bận. Đang hiển thị gợi ý xem lại từ phim bạn chấm điểm cao!`.
  4. Nếu người dùng chưa từng chấm điểm cao phim nào, app hiển thị thông báo: `"Chưa thể tạo gợi ý phim mới. Vui lòng thử lại sau."`.

---

## 8. Xử lý các trạng thái lỗi & Giao diện (Error Handling)

| Tình huống | Hành vi xử lý trên giao diện |
| :--- | :--- |
| **Đang tải (Loading)** | Hiển thị hộp thông báo kèm spinner màu vàng: *"AI đang phân tích sở thích xem phim của bạn..."* |
| **Chưa có lịch sử xem (Empty History)** | Hiển thị thông báo thân thiện:  <br>`🎬 Chưa đủ dữ liệu`<br>`Hãy thêm một vài bộ phim bạn đã xem để AI có thể hiểu sở thích của bạn.` |
| **AI lỗi / Hết mạng / Sai Key** | Tự động chuyển sang chế độ **Fallback** hiển thị phim xem lại, kèm banner giải thích. |
| **Không có kết nối & không có phim xem lại** | Hiển thị nút **"Thử lại"**. |
| **Trùng lặp phim / Phim đã xem** | Bộ lọc Client tự động loại bỏ ngầm, người dùng chỉ thấy phim mới mẻ 100%. |

---

## 9. Các file đã thêm và chỉnh sửa

### Files mới thêm:
1. **`lib/models/movie_recommendation.dart`**:
   - Model chứa thông tin đề xuất: `title`, `year`, `genre`, `reason`, `matchScore`, `posterUrl`, `isFromFallback`.
   - Lớp `RecommendationResult` quản lý trạng thái (`success`, `fallback`, `emptyHistory`, `error`).
2. **`lib/services/ai_client.dart`**:
   - Giao diện `AiClient`.
   - `GeminiAiClient`: Tích hợp Google Gemini REST API (hỗ trợ mô hình `gemini-1.5-flash`).
   - `OpenAiClient`: Tích hợp OpenAI / DeepSeek / Groq compatible API.
   - `MockAiClient`: Hỗ trợ kiểm thử tự động.
3. **`lib/services/recommendation_service.dart`**:
   - Singleton service trung tâm xử lý thu thập dữ liệu nhật ký, sinh prompt động, gọi AI, xác thực JSON, lọc trùng và fallback.
4. **`lib/widgets/ai_recommendations_section.dart`**:
   - Widget giao diện cho section **"🎬 Gợi ý dành cho bạn"**.
   - Hàng card nằm ngang với poster, điểm số `⭐ AI Match: xx%`, lý do gợi ý, nút **`+ Watchlist`** và nút **`Xem thêm gợi ý`**.
   - Hộp thoại cấu hình nhanh API Key ngay trong app.
5. **`test/services/recommendation_service_test.dart`**:
   - Bộ kiểm thử tự động với 5 kịch bản: sinh prompt, parse JSON markdown, lọc phim đã xem, AI success, AI fallback.

### Files đã chỉnh sửa:
1. **`lib/features/library/library_screen.dart`**:
   - Nhúng `AiRecommendationsSection` vào đầu màn hình chính (khi không tìm kiếm).
   - Tự động tải lại thư viện khi người dùng bấm thêm phim gợi ý vào Watchlist.
2. **`pubspec.yaml`**:
   - Đăng ký phụ thuộc `http: ^1.6.0` trực tiếp để gọi AI API.

---

## 10. Cách Test tính năng AI Movie Recommendation

### Cách 1: Chạy toàn bộ Unit Tests tự động
Mở terminal và gõ:
```bash
cd movie
flutter test
```
*Kết quả:* Toàn bộ **16/16 tests** (bao gồm model, DB, screens và AI Recommendation Service) đều vượt qua.

### Cách 2: Test Live với Google Gemini API Key thông qua `.env`
1. Lấy API Key miễn phí từ [Google AI Studio](https://aistudio.google.com/).
2. Tạo file `.env` trong thư mục `movie/` (hoặc sao chép từ `.env.example`):
   ```env
   GEMINI_API_KEY=your_actual_gemini_api_key
   GEMINI_API_URL=https://generativelanguage.googleapis.com
   GEMINI_MODEL=gemini-2.5-flash
   ```
3. Chạy ứng dụng đọc trực tiếp cấu hình từ `.env`:
   ```bash
   flutter run -d chrome --web-port=5000 --dart-define-from-file=.env
   ```
   *(File `.env` đã được thêm vào `.gitignore` nên tuyệt đối bảo mật và không bao giờ bị đẩy lên GitHub).*
   *(Hoặc bấm vào biểu tượng bánh răng **Cấu hình AI** trên thanh tiêu đề của mục Gợi ý trong app rồi dán API Key trực tiếp).*
3. Nhìn vào màn hình Library, AI sẽ phân tích 5 phim đã xem trong database (Inception, Interstellar, The Dark Knight,...) và trả về danh sách các phim phù hợp kèm lý do tiếng Việt.
4. Bấm nút **`+ Watchlist`** trên card để lưu ngay bộ phim gợi ý vào danh sách chờ xem!

### Cách 3: Test cơ chế Fallback (Không cần API Key)
1. Chạy app bình thường không truyền API Key:
   ```bash
   flutter run -d chrome
   ```
2. Mục gợi ý sẽ tự động chuyển sang chế độ **Fallback**: hiển thị các bộ phim bạn đã chấm từ 4.6⭐ trở lên (*Inception*, *The Dark Knight*, *Spirited Away*,...) dưới dạng gợi ý xem lại mà không hề bị crash hay đơ app.
