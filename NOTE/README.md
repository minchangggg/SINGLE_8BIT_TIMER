# NOTE
> DÙNG **Rising** EDGE CỦA TMR_Edge chứ ko pải FALLING như trong timming yc 

# TIMELINE
## 1. Hoàn thành các test cơ bản để ktra RTL hoạt động đúng với thiết kế ko => OK
### 1.1. Test_rw_reg_control_final => OK
> https://edaplayground.com/x/cGnu

<img width="1837" height="374" alt="image" src="https://github.com/user-attachments/assets/7c73c341-5de2-4b3a-98d6-d219aaa066c5" />

<img width="400" alt="image" src="https://github.com/user-attachments/assets/12ced262-2620-48fa-a937-6d580d2cfcde">
<img width="400" alt="image" src="https://github.com/user-attachments/assets/f68eeae5-66e0-4f79-bccf-b4d8be92ecc5">

### 1.2. Test_detect_cnt_edge => OK
> https://edaplayground.com/x/tWNf

<img width="1873" height="304" alt="image" src="https://github.com/user-attachments/assets/25e7f094-0af5-4d91-ad0d-eff8933d5ba6" />

<img width="700" alt="image" src="https://github.com/user-attachments/assets/e12778c4-fdb6-4cbe-ac87-311d132b4df5">

### 1.3. Test_counter_unit => OK
> https://edaplayground.com/x/etm8

<img width="1898" height="363" alt="image" src="https://github.com/user-attachments/assets/5e204f78-900c-4672-8c0a-6fb333e29883" />

> tmr_clk = pclk/8

### 1.4. Test_ovf_udf => OK
> https://edaplayground.com/x/FBu8

<img width="1904" height="306" alt="image" src="https://github.com/user-attachments/assets/22189632-4d4f-4e00-85a4-eb2d053fba94" />

--------------------------------------------------------------------------------------------------------------------------------------

## 2. Hoàn chỉnh RTL
> https://edaplayground.com/x/fhFF

--------------------------------------------------------------------------------------------------------------------------------------

## 3. Viết code cho Testcase theo Test Plan
> https://1drv.ms/x/c/bf59f56abe5fcd4f/Eds4H4kc0WpNjWQHSV2JZrMBLutPPjJqdwPW6FP6gh2HKA?e=6qRTJV

### 3.1. Testcase 1,2,3,4,5 => chưa OK
<img width="1746" height="542" alt="image" src="https://github.com/user-attachments/assets/a72eee28-3e88-4e19-978c-b1a449f8806c" />

<img width="1818" height="579" alt="image" src="https://github.com/user-attachments/assets/ca67700d-65b3-4f67-bb91-4c89228cc456" />

> Kiểm tra Thanh ghi (Register Tests)
- [ ] Testcase1 - tdr_test.v: Kiểm tra đọc và ghi vào thanh ghi TDR.
- [ ] Testcase2 - tcr_test.v: Kiểm tra đọc và ghi vào thanh ghi TCR và xác minh các bit chức năng.
- [ ] Testcase3 - tsr_test.v: Kiểm tra đọc và ghi vào thanh ghi TSR và xác minh các cờ trạng thái.
- [ ] Testcase4 - null_address.v: Kiểm tra ghi vào một địa chỉ không tồn tại và xác minh lỗi PSLVERR.
- [ ] Testcase5 - mixed_address.v: Kiểm tra truy cập đồng thời vào nhiều địa chỉ khác nhau.

### 3.2. Testcase 20,21 => chưa OK
<img width="1747" height="230" alt="image" src="https://github.com/user-attachments/assets/1468e29e-d24c-4793-9e99-b860c2f903c9" />

### 3.3. Testcase 6,7,8,9 => chưa OK
<img width="1709" height="621" alt="image" src="https://github.com/user-attachments/assets/e965e9e9-469d-4971-8f57-232f59d90ac3" />









