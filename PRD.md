# PRD – ĐẢO ĐÈN LỒNG

**Product Requirements Document – Phase 1**

| Thông tin | Nội dung |
|---|---|
| Tên sản phẩm | Đảo Đèn Lồng |
| Phiên bản PRD | 1.0 – Draft |
| Phiên bản game | Phase 1 |
| Thể loại | Phiêu lưu 3D, thu thập, sinh tồn nhẹ |
| Nền tảng | macOS, Linux; phát triển được trên Windows |
| Công nghệ đề xuất | Godot 4 + GDScript |
| Chế độ | Single-player |
| Màn chơi | Đêm 1 – Đảo Bến |
| Ưu tiên | Gameplay đúng yêu cầu và Test Contract |

---

## 1. Tổng quan sản phẩm

### 1.1. Giới thiệu

Đảo Đèn Lồng là game phiêu lưu 3D mang phong cách cổ tích.

Người chơi hóa thân thành **Mây**, một người giữ đèn nhỏ tuổi sống trên hòn đảo giữa biển mây.

Một đêm, sương đen bao phủ hòn đảo, khiến năm Đèn Lồng Lớn ngừng phát sáng.

Nhiệm vụ của Mây là:

1. Khám phá hòn đảo.
2. Thu thập đom đóm để tích trữ ánh sáng.
3. Tránh né Bóng Mực.
4. Sử dụng kỹ năng tỏa sáng để xua đuổi kẻ địch.
5. Mang ánh sáng đến năm Đèn Lồng Lớn.
6. Thắp sáng toàn bộ hòn đảo.

### 1.2. Mục tiêu sản phẩm

- Xây dựng một game 3D có thể chơi hoàn chỉnh.
- Có cơ chế di chuyển, thu thập, tương tác, chiến đấu phòng thủ đơn giản.
- Có điều kiện thắng và thua rõ ràng.
- Có HUD và hệ thống tính điểm.
- Hỗ trợ chạy headless theo Test Contract v1.0.
- Có thể kiểm thử và tái hiện kết quả.
- Có thể bàn giao bằng Git tag `phase-1`.

### 1.3. Định nghĩa hoàn thành

Phase 1 được xem là hoàn thành khi:

- Người chơi có thể bắt đầu một ván mới.
- Toàn bộ chức năng bắt buộc hoạt động.
- Có thể chơi từ đầu đến thắng hoặc thua.
- Có thể chơi lại sau khi ván kết thúc.
- Kiểm thử theo Test Contract v1.0 đạt yêu cầu.
- Có bằng chứng chạy thực tế.
- Repository public và có tag `phase-1`.

---

## 2. Đối tượng người chơi

Game hướng đến người chơi yêu thích:

- Game phiêu lưu nhẹ nhàng.
- Đồ họa 3D cổ tích.
- Khám phá và thu thập vật phẩm.
- Những thử thách đơn giản nhưng có mục tiêu rõ ràng.

Không sử dụng hình ảnh máu me hoặc bạo lực nặng.

---

## 3. Phạm vi Phase 1

### 3.1. Chức năng bắt buộc – P0

| ID | Chức năng | Ưu tiên |
|---|---|---|
| FR-01 | Khởi tạo màn chơi 3D | P0 |
| FR-02 | Điều khiển nhân vật Mây | P0 |
| FR-03 | Camera 3D theo nhân vật | P0 |
| FR-04 | Hệ thống thu thập đom đóm | P0 |
| FR-05 | Hệ thống ánh sáng tích trữ | P0 |
| FR-06 | Tương tác và thắp Đèn Lồng Lớn | P0 |
| FR-07 | Bóng Mực phát hiện, đuổi theo và gây sát thương | P0 |
| FR-08 | Kỹ năng tỏa sáng xua Bóng Mực | P0 |
| FR-09 | Hệ thống máu | P0 |
| FR-10 | Hệ thống điểm số | P0 |
| FR-11 | Điều kiện chiến thắng | P0 |
| FR-12 | Điều kiện thất bại | P0 |
| FR-13 | Giao diện HUD | P0 |
| FR-14 | Chơi lại sau thắng hoặc thua | P0 |
| FR-15 | Chế độ headless và Test Contract | P0 |
| FR-16 | Tài liệu, bằng chứng và bàn giao Git | P0 |

### 3.2. Chức năng sáng tạo – P1

Chỉ thực hiện sau khi hoàn thành P0.

- Đom đóm có màu sắc khác nhau.
- Hạt sáng bay xung quanh nhân vật.
- Sương đen mờ dần khi các đèn được thắp.
- Nhạc nền thay đổi theo mức độ sáng của đảo.
- Hiệu ứng đèn lồng phát sáng khi được kích hoạt.

Các tính năng sáng tạo không được thay đổi kết quả headless theo Test Contract.

### 3.3. Ngoài phạm vi Phase 1

- Multiplayer.
- Nhiều màn chơi.
- Hệ thống nhiệm vụ phụ phức tạp.
- Cửa hàng và hệ thống tiền tệ.
- Hệ thống trang bị.
- Tài khoản người dùng.
- Lưu tiến trình giữa nhiều phiên chơi.
- Backend trực tuyến.

---

## 4. Thiết kế màn chơi

### FR-01 – Đêm 1: Đảo Bến

**Mô tả**

Một hòn đảo hình tròn nổi giữa biển mây. Ban đầu, phần lớn đảo chìm trong bóng tối.

**Yêu cầu**

- Có mặt đất 3D và hệ thống va chạm.
- Nhân vật không thể đi xuyên qua địa hình.
- Có đúng 5 Đèn Lồng Lớn cần thắp.
- Các đèn được đặt tại những vị trí khác nhau trên đảo.
- Có các vị trí xuất hiện đom đóm.
- Có Bóng Mực trong khu vực chơi.
- Có ánh sáng môi trường tối thiểu để người chơi quan sát được đường đi.

**Điều kiện nghiệm thu**

- Người chơi có thể di chuyển và khám phá đảo.
- Cả 5 đèn đều có thể tiếp cận.
- Không có đèn bắt buộc nào nằm ngoài vùng chơi.
- Tất cả vị trí quan trọng đều có thể đến được.

---

## 5. Nhân vật và điều khiển

### FR-02 – Nhân vật Mây

Mây là nhân vật 3D đội nón lá, có một chiếc đèn lồng nhỏ treo trên nón.

**Chức năng**

- Đi tiến, lùi, trái, phải.
- Nhảy.
- Chịu tác động của trọng lực.
- Va chạm với mặt đất và vật cản.
- Không được nhảy liên tục trên không nếu chưa tiếp đất.

### FR-03 – Camera

- Góc nhìn người thứ ba.
- Camera theo chuyển động nhân vật.
- Nhân vật luôn nằm trong vùng quan sát.
- Camera không gây mất khả năng điều khiển.

### Quy định điều khiển đề xuất

| Phím | Chức năng |
|---|---|
| W | Tiến |
| S | Lùi |
| A | Sang trái |
| D | Sang phải |
| Space | Nhảy |
| E | Tương tác với đèn |
| F | Tỏa sáng |
| Chuột | Xoay camera |

Các phím này là đề xuất và có thể điều chỉnh trong thiết kế kỹ thuật.

---

## 6. Hệ thống ánh sáng và đom đóm

### FR-04 – Thu thập đom đóm

**Mô tả**

Đom đóm xuất hiện tại nhiều vị trí trên đảo. Người chơi đi đến gần để thu thập.

**Yêu cầu**

- Đom đóm là thực thể 3D có thể nhìn thấy.
- Có hiệu ứng phát sáng.
- Khi người chơi chạm vào, đom đóm được thu thập.
- Một đom đóm không thể được thu thập hai lần nếu chưa tái xuất hiện.
- Đom đóm tiếp tục có thể xuất hiện để người chơi có đủ tài nguyên hoàn thành màn chơi.

### FR-05 – Năng lượng ánh sáng

**Quy tắc gameplay đề xuất**

| Thông số | Giá trị |
|---|---|
| Ánh sáng ban đầu | 0 |
| Ánh sáng tối đa | 10 |
| Nhặt một đom đóm | +1 ánh sáng |
| Thắp một đèn lớn | -3 ánh sáng |
| Sử dụng tỏa sáng | -2 ánh sáng |

**Điều kiện nghiệm thu**

- Không thể vượt quá giới hạn ánh sáng.
- Không thể sử dụng nhiều ánh sáng hơn lượng hiện có.
- HUD cập nhật khi ánh sáng thay đổi.
- Thu thập và tiêu hao ánh sáng phải được xử lý nhất quán.

---

## 7. Hệ thống Đèn Lồng Lớn

### FR-06 – Thắp đèn

Màn chơi có đúng 5 Đèn Lồng Lớn.

Mỗi đèn có hai trạng thái chính:

- **Unlit:** Chưa sáng.
- **Lit:** Đã sáng.

**Luồng tương tác**

1. Mây đến gần một đèn chưa sáng.
2. Hệ thống nhận biết khoảng cách tương tác.
3. HUD hiển thị gợi ý nhấn E.
4. Người chơi nhấn E.
5. Kiểm tra lượng ánh sáng đang có.
6. Nếu đủ, trừ ánh sáng và đổi trạng thái đèn thành Lit.
7. Bật hiệu ứng phát sáng và cập nhật tiến trình.
8. Nếu không đủ, đèn vẫn ở trạng thái Unlit.

**Quy tắc**

- Một đèn đã sáng không thể tiêu hao ánh sáng thêm lần nữa.
- Trạng thái đèn phải được lưu trong trạng thái ván chơi.
- Bóng Mực phải sợ hoặc tránh vùng sáng của đèn.
- Khi cả 5 đèn chuyển sang Lit, kích hoạt chiến thắng.

**Điều kiện nghiệm thu**

- Không thể thắp đèn khi thiếu ánh sáng.
- Mỗi đèn chỉ được thắp thành công một lần.
- Tiến trình tăng chính xác từ 0/5 đến 5/5.
- Đèn sáng có thay đổi trực quan.

---

## 8. Hệ thống kẻ địch

### FR-07 – Bóng Mực

Bóng Mực là sinh vật màu tím đen sinh sống trong sương.

**Các trạng thái AI đề xuất**

| Trạng thái | Hành vi |
|---|---|
| Wander | Di chuyển quanh khu vực |
| Chase | Đuổi theo Mây khi phát hiện |
| Repelled | Rút lui khi bị tỏa sáng |
| AvoidLight | Tránh vùng sáng của Đèn Lồng Lớn |

**Yêu cầu**

- Bóng Mực có thể phát hiện người chơi trong phạm vi nhất định.
- Có thể di chuyển và đuổi theo Mây.
- Khi tiếp xúc hợp lệ, gây sát thương.
- Không gây sát thương liên tục mỗi frame.
- Bị đẩy lùi bởi kỹ năng tỏa sáng.
- Không chủ động đi vào vùng sáng an toàn của đèn.

**Giả định cân bằng**

- Mỗi lần chạm hợp lệ gây 1 sát thương.
- Sau khi nhận sát thương, người chơi có 1 giây miễn nhiễm tạm thời.

**Điều kiện nghiệm thu**

- Bóng Mực có thể đuổi người chơi đang di chuyển.
- Có thể gây sát thương khi tiếp xúc.
- Không thể trừ hết máu trong một lần chạm chỉ vì nhiều frame liên tục.
- Có phản ứng rõ ràng với ánh sáng.

---

## 9. Kỹ năng tỏa sáng

### FR-08 – Tỏa sáng

Mây sử dụng ánh sáng tích trữ để đẩy lùi Bóng Mực trong phạm vi gần.

**Luồng xử lý**

1. Người chơi nhấn F.
2. Kiểm tra trạng thái ván chơi.
3. Kiểm tra đủ năng lượng.
4. Kiểm tra thời gian hồi kỹ năng.
5. Nếu hợp lệ, tiêu hao ánh sáng.
6. Phát hiệu ứng tỏa sáng.
7. Bóng Mực trong phạm vi chuyển sang trạng thái bị xua đuổi.
8. Bắt đầu thời gian hồi kỹ năng.

**Giả định đề xuất**

- Chi phí: 2 ánh sáng.
- Thời gian tác dụng: 2 giây.
- Thời gian hồi: 3 giây.

**Điều kiện nghiệm thu**

- Thiếu ánh sáng không thể kích hoạt.
- Đang hồi chiêu không thể kích hoạt lần nữa.
- Khi kích hoạt hợp lệ, năng lượng bị trừ đúng một lần.
- Bóng Mực trong phạm vi có phản ứng.

---

## 10. Hệ thống máu

### FR-09 – Health System

**Giả định đề xuất**

- Máu tối đa: 3.
- Máu ban đầu: 3.
- Một lần nhận sát thương hợp lệ: -1.
- Máu tối thiểu: 0.

**Yêu cầu**

- HUD thể hiện máu hiện tại.
- Máu không được nhỏ hơn 0.
- Khi máu giảm về 0, game chuyển sang trạng thái thua.
- Khi game đã kết thúc, không tiếp tục tính sát thương.

---

## 11. Hệ thống tính điểm

### FR-10 – Score System

Hệ thống điểm dùng để ghi nhận kết quả của người chơi.

**Cách tính đề xuất**

| Hành động | Điểm |
|---|---:|
| Thu thập một đom đóm | +10 |
| Thắp thành công một đèn lớn | +100 |
| Mỗi máu còn lại khi chiến thắng | +50 |
| Kích hoạt lại đèn đã sáng | +0 |

Điểm thưởng máu còn lại chỉ được cộng một lần khi thắng.

**Yêu cầu**

- Điểm được cập nhật chính xác sau mỗi sự kiện.
- Không cộng điểm trùng lặp.
- Hiển thị điểm trong HUD.
- Khi kết thúc, điểm cuối cùng được hiển thị.
- Khi chơi lại, điểm trở về 0.

Công thức này là giả định; nếu Test Contract quy định khác thì sử dụng công thức của contract.

---

## 12. Điều kiện thắng và thua

### FR-11 – Chiến thắng

**Điều kiện**

Tất cả 5 Đèn Lồng Lớn đã được thắp sáng và nhân vật còn sống.

**Kết quả**

- Chuyển trạng thái game sang Won.
- Dừng gameplay đang diễn ra.
- Hiển thị thông báo chiến thắng.
- Hiển thị điểm cuối cùng.
- Cho phép chơi lại.

### FR-12 – Thất bại

**Điều kiện**

Máu của Mây giảm về 0 trước khi hoàn thành việc thắp đèn.

**Kết quả**

- Chuyển trạng thái game sang Lost.
- Dừng gameplay đang diễn ra.
- Hiển thị thông báo thất bại.
- Hiển thị điểm cuối cùng.
- Cho phép chơi lại.

**Quy tắc trạng thái**

Một ván chơi chỉ có một trạng thái kết thúc: Won hoặc Lost.

Nếu sự kiện thắng và thua xảy ra gần như đồng thời, hệ thống phải có quy tắc xử lý xác định và kiểm thử được. Quy tắc cuối cùng cần tuân theo Test Contract.

---

## 13. Giao diện HUD

### FR-13 – HUD

Trong khi chơi, màn hình phải hiển thị:

| Thành phần | Nội dung |
|---|---|
| Health | Máu hiện tại |
| Light | Năng lượng ánh sáng |
| Lantern Progress | Số đèn đã thắp / 5 |
| Score | Điểm hiện tại |
| Interaction Hint | Gợi ý khi đến gần đèn |
| Skill Status | Trạng thái kỹ năng tỏa sáng |

### FR-14 – Kết thúc và chơi lại

Khi thắng hoặc thua:

- Hiển thị màn hình kết quả.
- Hiển thị điểm cuối cùng.
- Có nút Replay.

Khi chọn Replay:

- Máu trở về giá trị ban đầu.
- Ánh sáng trở về 0.
- Điểm trở về 0.
- Năm đèn trở về trạng thái chưa sáng.
- Nhân vật trở về vị trí xuất phát.
- Bóng Mực và đom đóm được khởi tạo lại.
- Trạng thái ván chơi trở về Playing.

---

## 14. Vòng đời và luồng gameplay

### 14.1. Các trạng thái chính

- Initializing: Khởi tạo game.
- Playing: Đang chơi.
- Won: Chiến thắng.
- Lost: Thất bại.
- Restarting: Đang khởi tạo lại ván chơi.

### 14.2. Luồng gameplay

**Khởi động → Tạo đảo và nhân vật → Playing**

Trong Playing:

- Di chuyển và khám phá.
- Thu thập đom đóm.
- Tích trữ ánh sáng.
- Đối phó với Bóng Mực.
- Thắp Đèn Lồng Lớn.
- Cập nhật điểm và HUD.

Sau mỗi sự kiện quan trọng:

- Nếu máu về 0, chuyển Lost.
- Nếu 5 đèn đã thắp và người chơi còn sống, chuyển Won.
- Nếu chưa thỏa điều kiện kết thúc, tiếp tục Playing.

Khi kết thúc:

**Won/Lost → Replay → Restarting → Playing**

---

## 15. Dữ liệu và trạng thái

### 15.1. Game State

Hệ thống cần quản lý tối thiểu:

| Trường logic | Ý nghĩa |
|---|---|
| game_status | Trạng thái ván chơi |
| health | Máu hiện tại |
| max_health | Máu tối đa |
| light | Ánh sáng hiện tại |
| max_light | Giới hạn ánh sáng |
| score | Điểm hiện tại |
| lanterns_lit | Số lượng đèn đã thắp |
| lanterns_total | Tổng số đèn bắt buộc |
| player_position | Vị trí nhân vật |

### 15.2. Lantern State

Mỗi đèn cần có:

- ID duy nhất.
- Vị trí.
- Trạng thái đã thắp hay chưa.
- Lượng ánh sáng cần để thắp.
- Vùng ảnh hưởng ánh sáng.

### 15.3. Firefly State

Mỗi đom đóm cần có:

- ID.
- Vị trí.
- Trạng thái có thể thu thập.
- Giá trị ánh sáng cung cấp.

### 15.4. Enemy State

Mỗi Bóng Mực cần có:

- ID.
- Vị trí.
- Trạng thái hành vi AI.
- Mục tiêu di chuyển.
- Trạng thái bị xua đuổi.
- Khả năng gây sát thương.

Các cấu trúc dữ liệu này dùng cho thiết kế nội bộ. Định dạng JSON bên ngoài phải theo Test Contract v1.0, không được tự ý thay thế.

---

## 16. Yêu cầu phi chức năng

### 16.1. Hiệu năng

- Game có khả năng chạy trên laptop thông thường.
- Đề xuất mục tiêu 30 FPS hoặc cao hơn trên cấu hình được xác định khi kiểm thử.
- Hạn chế hiệu ứng nặng không cần thiết.
- Không yêu cầu GPU cao cấp.

### 16.2. Khả năng tương thích

- Chạy được trên macOS hoặc Linux.
- Nếu phát triển trên Windows, phải có hướng dẫn chạy thực tế cho giảng viên trên macOS/Linux.
- Không phụ thuộc vào đường dẫn tuyệt đối trên máy lập trình viên.
- Không phụ thuộc dịch vụ Internet để chơi.

### 16.3. Độ ổn định

- Không crash khi bắt đầu hoặc chơi lại.
- Không có lỗi khiến người chơi không thể hoàn thành màn chơi.
- Không có trạng thái game mâu thuẫn.
- Các sự kiện ghi điểm, máu, ánh sáng không bị xử lý trùng lặp.

### 16.4. Khả năng bảo trì

- Mỗi hệ thống có trách nhiệm rõ ràng.
- Hạn chế logic trùng lặp.
- Dễ kiểm thử các quy tắc gameplay độc lập với đồ họa.
- Thay đổi giao diện không làm ảnh hưởng đến logic tính điểm và trạng thái.

---

## 17. Chế độ Headless và Test Contract

### FR-15 – Test Contract Compliance

**Mục tiêu**

Cho phép hệ thống kiểm thử tự động đánh giá game mà không cần mở giao diện đồ họa.

**Yêu cầu**

1. Cung cấp file `game.contract.json`.
2. Hỗ trợ chế độ headless.
3. Đọc và xử lý dữ liệu kiểm thử theo Test Contract v1.0.
4. Xuất kết quả chính xác theo định dạng contract quy định.
5. Hành vi kiểm thử có thể tái hiện.
6. Không để hiệu ứng hoặc chức năng sáng tạo làm thay đổi kết quả contract.
7. Không được tự tạo schema đầu vào, đầu ra thay cho Test Contract.

**Quy tắc kiến trúc**

Gameplay logic phải được tách hợp lý khỏi:

- Render 3D.
- Camera.
- Hiệu ứng hình ảnh.
- Âm thanh.
- HUD.

Các phép tính logic phải có khả năng kiểm thử mà không phụ thuộc giao diện.

**Các nhóm kiểm thử cần triển khai sau khi nhận Test Contract**

- Trạng thái khởi tạo.
- Thu thập ánh sáng.
- Tiêu hao ánh sáng.
- Thắp đèn thành công hoặc thất bại.
- Nhận sát thương.
- Tỏa sáng xua địch.
- Điều kiện thắng.
- Điều kiện thua.
- Khởi tạo lại game.
- Tính điểm.
- Định dạng dữ liệu và kết quả headless.

**Chưa được chốt**

- Schema chính xác của `game.contract.json`.
- Đầu vào và đầu ra headless.
- Các lệnh bắt buộc.
- Mã thoát, lỗi và định dạng thông báo.
- Các quy tắc gameplay mà contract có thể đã cố định.

Các nội dung này sẽ được cập nhật từ bản Test Contract v1.0 gốc trước khi lập trình phần tích hợp.

---

## 18. Kịch bản kiểm thử nghiệm thu

| Test ID | Kịch bản | Kết quả mong đợi |
|---|---|---|
| TC-01 | Khởi động game | Nhân vật xuất hiện trên đảo |
| TC-02 | Nhấn WASD | Nhân vật di chuyển |
| TC-03 | Nhấn Space khi trên đất | Nhân vật nhảy |
| TC-04 | Nhặt đom đóm | Ánh sáng tăng |
| TC-05 | Nhặt khi ánh sáng đã tối đa | Không vượt giới hạn |
| TC-06 | Thắp đèn khi thiếu ánh sáng | Thất bại, không tiêu hao |
| TC-07 | Thắp đèn khi đủ ánh sáng | Đèn sáng, năng lượng giảm |
| TC-08 | Tương tác với đèn đã sáng | Không bị trừ thêm ánh sáng |
| TC-09 | Bóng Mực chạm người chơi | Máu giảm hợp lệ |
| TC-10 | Kích hoạt tỏa sáng khi đủ năng lượng | Bóng Mực gần bị xua |
| TC-11 | Kích hoạt tỏa sáng khi thiếu năng lượng | Không kích hoạt |
| TC-12 | Bóng Mực ở gần đèn đã sáng | Thực hiện hành vi tránh vùng sáng |
| TC-13 | Thắp đèn thứ năm khi còn sống | Chiến thắng |
| TC-14 | Máu giảm về 0 trước khi hoàn thành | Thất bại |
| TC-15 | Nhấn Replay | Tạo ván chơi mới với trạng thái ban đầu |
| TC-16 | Thu thập và thắp nhiều đèn | Điểm tính đúng, không cộng trùng |
| TC-17 | Chạy trên macOS/Linux | Game khởi động và chơi được |
| TC-18 | Chạy headless | Đạt toàn bộ tiêu chí Test Contract v1.0 |

Bộ test cần có cả trường hợp hợp lệ, không hợp lệ và các trường hợp biên.

---

## 19. Kế hoạch triển khai

Chia thành các giai đoạn nhỏ để AI Agent có thể thực hiện và kiểm thử độc lập.

| Giai đoạn | Công việc | Kết quả |
|---|---|---|
| 1 | Khởi tạo Godot và kiến trúc | Project chạy được |
| 2 | Tạo đảo, nhân vật, camera | Có thể di chuyển trong 3D |
| 3 | Đom đóm và ánh sáng | Thu thập được tài nguyên |
| 4 | Hệ thống 5 đèn | Có thể thắp đèn |
| 5 | AI Bóng Mực và máu | Có địch và sát thương |
| 6 | Kỹ năng tỏa sáng | Có thể xua địch |
| 7 | Điểm, HUD, thắng/thua | Gameplay hoàn chỉnh |
| 8 | Replay | Chơi lại chính xác |
| 9 | Headless và Test Contract | Kiểm thử tự động đạt yêu cầu |
| 10 | Hoàn thiện đồ họa, âm thanh | Phong cách cổ tích |
| 11 | Kiểm thử macOS/Linux | Chạy trên nền tảng yêu cầu |
| 12 | README, bằng chứng, Git tag | Sẵn sàng bàn giao |

**Quy tắc thực hiện**

- Mỗi giai đoạn có tiêu chí nghiệm thu rõ ràng.
- Agent phải chạy kiểm thử thay vì chỉ báo đã hoàn thành.
- Không tiếp tục một chức năng phụ thuộc nếu chức năng nền tảng đang lỗi.
- Ưu tiên sửa lỗi P0 trước khi phát triển P1.
- Bằng chứng phải được tạo từ kết quả chạy thực tế.

---

## 20. Sáng tạo của tôi

Phần sáng tạo được đề xuất cho Phase 1:

**Ánh sáng hồi sinh hòn đảo**

Khi Mây thắp một Đèn Lồng Lớn:

- Xuất hiện một làn sóng ánh sáng vàng cam.
- Sương đen xung quanh mờ dần.
- Màu sắc cây cỏ trở nên ấm áp hơn.
- Những hạt sáng nhỏ bay quanh ngọn đèn.

Khi cả 5 đèn được thắp sáng, đảo chuyển từ một không gian tối sang khung cảnh cổ tích lung linh.

Đây là cơ chế thể hiện hình ảnh, không tự ý thay đổi quy tắc gameplay hoặc kết quả headless.

README phải mô tả tính năng này và ghi nhận rằng các kiểm thử bắt buộc vẫn đạt yêu cầu.

---

## 21. Giả định cần ghi nhận

Các thông số dưới đây chưa được PRD-0 quy định cụ thể, được đề xuất để bắt đầu thiết kế:

| Nội dung | Giả định |
|---|---|
| Máu ban đầu | 3 |
| Ánh sáng tối đa | 10 |
| Ánh sáng từ đom đóm | 1 |
| Chi phí thắp đèn | 3 |
| Chi phí tỏa sáng | 2 |
| Thời gian miễn nhiễm sau sát thương | 1 giây |
| Thời gian tác dụng tỏa sáng | 2 giây |
| Hồi kỹ năng | 3 giây |
| Số Đèn Lồng Lớn | 5 |
| Góc nhìn | Camera thứ ba |
| Điểm thu thập đom đóm | 10 |
| Điểm thắp đèn | 100 |

Mọi giả định mâu thuẫn với Test Contract v1.0 đều phải được điều chỉnh theo contract. Không xem bảng giả định là yêu cầu cao hơn Test Contract.

---

## 22. Bàn giao Phase 1

### FR-16 – Deliverables

Repository public phải có:

- Mã nguồn game và các tài nguyên cần thiết.
- File `README.md`.
- File `game.contract.json`.
- Mã nguồn hoặc cấu hình hỗ trợ headless.
- Tài liệu hoặc ghi chép về giả định.
- Bằng chứng kiểm thử và game chạy thực tế.
- Nhật ký ngắn về quá trình sử dụng AI.
- AI harness đã sử dụng, ví dụ `AGENTS.md`, skills và hooks nếu có.
- Git tag `phase-1`.

### README.md phải có

1. Giới thiệu game.
2. Cách cài đặt và chạy, tối đa 3 lệnh.
3. Hướng dẫn điều khiển.
4. Quy tắc tính điểm.
5. Cách chạy và kiểm tra headless theo Test Contract.
6. Mục "Sáng tạo của tôi".
7. Bằng chứng ngắn cho thấy chức năng cũ vẫn đúng.

### Tiêu chí nghiệm thu cuối cùng

Phase 1 chỉ được chấp nhận khi:

- Gameplay có thể hoàn thành từ đầu đến cuối.
- Đầy đủ các chức năng P0.
- Có cả kết quả thắng và thua.
- Chơi lại hoạt động.
- Chạy được trên nền tảng quy định.
- Các kiểm thử bắt buộc theo Test Contract v1.0 thành công.
- Bằng chứng có thể kiểm tra độc lập.
- Repository public có tag `phase-1`.

---

**Kết luận:** Sản phẩm Phase 1 cần ưu tiên tính đúng đắn, khả năng chạy và kiểm thử tự động. Mọi cải tiến về hình ảnh, âm thanh và sáng tạo phải phục vụ trải nghiệm người chơi, không được làm hỏng các yêu cầu bắt buộc.