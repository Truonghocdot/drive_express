import PptxGenJS from '../.tmp-slide-tools/node_modules/pptxgenjs/dist/pptxgen.es.js';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const pptx = new PptxGenJS();
pptx.layout = 'LAYOUT_WIDE';
pptx.author = 'Graduation project';
pptx.company = 'FastRide Express';
pptx.subject = 'Bảo vệ đồ án nền tảng Delivery & Drive';
pptx.title = 'FastRide Express - Delivery & Drive';
pptx.lang = 'vi-VN';
pptx.theme = {
  headFontFace: 'Arial',
  bodyFontFace: 'Arial',
  lang: 'vi-VN',
};
pptx.defineSlideMaster({
  title: 'BASE',
  background: { color: 'F6F8FB' },
  objects: [],
  slideNumber: { x: 12.72, y: 7.08, color: '80909F', fontFace: 'Arial', fontSize: 9 },
});

const ST = pptx.ShapeType;
const W = 13.333;
const H = 7.5;
const C = {
  navy: '0B1B2B',
  navy2: '13283B',
  ink: '142333',
  muted: '617180',
  line: 'D9E2E8',
  paper: 'F6F8FB',
  white: 'FFFFFF',
  mint: '18C98B',
  mintDark: '006B57',
  mintPale: 'DDF8EE',
  teal: '0E8F82',
  amber: 'F4B942',
  amberPale: 'FFF2CF',
  coral: 'F36C5B',
  coralPale: 'FFE4DE',
  blue: '4F86D9',
  bluePale: 'E7F0FF',
  lilac: '7667D9',
  lilacPale: 'EEEAFE',
};
const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const ASSET = (...parts) => path.join(ROOT, ...parts);
const IMG = {
  logo: ASSET('docs', 'design', 'client', 'fastride_express_logo', 'screen.png'),
  clientHome: ASSET('docs', 'design', 'client', 'home', 'screen.png'),
  clientProfile: ASSET('docs', 'design', 'client', 'profile', 'screen.png'),
  clientActivities: ASSET('docs', 'design', 'client', 'activities', 'screen.png'),
  driverHistory: ASSET('docs', 'design', 'driver', 'history', 'screen.png'),
  driverProfile: ASSET('docs', 'design', 'driver', 'profile', 'screen.png'),
  driverWallet: ASSET('docs', 'design', 'driver', 'wallet', 'screen.png'),
};

function tx(slide, text, x, y, w, h, opts = {}) {
  slide.addText(text, {
    x, y, w, h,
    margin: 0,
    fontFace: opts.fontFace ?? 'Arial',
    fontSize: opts.fontSize ?? 16,
    color: opts.color ?? C.ink,
    bold: opts.bold ?? false,
    italic: opts.italic ?? false,
    align: opts.align ?? 'left',
    valign: opts.valign ?? 'mid',
    breakLine: false,
    fit: 'shrink',
    paraSpaceAfterPt: 0,
    lineSpacingMultiple: 1,
    charSpacing: 0,
  });
}

function rect(slide, x, y, w, h, fill, radius = true, line = null) {
  slide.addShape(radius ? ST.roundRect : ST.rect, {
    x, y, w, h,
    rectRadius: 0.08,
    fill: { color: fill },
    line: line ?? { color: fill, transparency: 100 },
  });
}

function line(slide, x1, y1, x2, y2, color = C.line, width = 1.2, arrow = false, dash = 'solid') {
  slide.addShape(ST.line, {
    x: x1, y: y1, w: x2 - x1, h: y2 - y1,
    line: {
      color, width, dashType: dash,
      beginArrowType: 'none',
      endArrowType: arrow ? 'triangle' : 'none',
    },
  });
}

function circle(slide, x, y, d, fill, lineColor = fill, lineWidth = 0) {
  slide.addShape(ST.ellipse, {
    x, y, w: d, h: d,
    fill: { color: fill },
    line: { color: lineColor, width: lineWidth, transparency: lineWidth ? 0 : 100 },
  });
}

function addFooter(slide, n, source = '') {
  line(slide, 0.55, 7.02, 12.75, 7.02, C.line, 0.65);
  tx(slide, source, 0.58, 7.08, 8.8, 0.18, { fontSize: 7.5, color: '85929E' });
  tx(slide, String(n).padStart(2, '0'), 12.25, 7.06, 0.45, 0.2, { fontSize: 8.5, color: C.muted, bold: true, align: 'right' });
}

function addHeader(slide, kicker, title, subtitle = '') {
  tx(slide, kicker.toUpperCase(), 0.62, 0.42, 4.2, 0.22, { fontSize: 9, color: C.teal, bold: true });
  tx(slide, title, 0.62, 0.72, 11.7, 0.55, { fontSize: 28, color: C.navy, bold: true });
  if (subtitle) tx(slide, subtitle, 0.64, 1.35, 11.7, 0.34, { fontSize: 12, color: C.muted });
}

function pill(slide, label, x, y, w, fill, color = C.navy, opts = {}) {
  rect(slide, x, y, w, opts.h ?? 0.32, fill, true);
  tx(slide, label, x, y + 0.01, w, (opts.h ?? 0.32) - 0.02, { fontSize: opts.fontSize ?? 9, color, bold: true, align: 'center' });
}

function card(slide, x, y, w, h, fill = C.white, border = C.line) {
  rect(slide, x, y, w, h, fill, true, { color: border, width: 0.7 });
}

function iconBadge(slide, x, y, d, fill, label, color = C.navy, fontSize = 15) {
  circle(slide, x, y, d, fill);
  tx(slide, label, x, y + 0.01, d, d - 0.02, { fontSize, bold: true, color, align: 'center' });
}

function image(slide, p, x, y, w, h, opts = {}) {
  slide.addImage({ path: p, x, y, w, h, transparency: opts.transparency ?? 0 });
}

function notes(slide, text) {
  slide.addNotes(text);
}

// 1. Title
{
  const s = pptx.addSlide();
  s.background = { color: C.navy };
  s.addShape(ST.rect, { x: 0, y: 0, w: W, h: H, fill: { color: C.navy }, line: { color: C.navy, transparency: 100 } });
  s.addShape(ST.arc, { x: 8.35, y: -1.35, w: 6.2, h: 6.2, adjustPoint: 0.22, line: { color: C.mint, transparency: 78, width: 1.6 }, fill: { color: C.navy, transparency: 100 } });
  s.addShape(ST.arc, { x: 9.35, y: 4.15, w: 4.7, h: 4.7, adjustPoint: 0.22, line: { color: C.amber, transparency: 78, width: 1.1 }, fill: { color: C.navy, transparency: 100 } });
  image(s, IMG.logo, 0.75, 0.68, 0.92, 0.92);
  tx(s, 'FAST RIDE', 1.86, 0.76, 2.6, 0.22, { fontSize: 10, color: C.mint, bold: true });
  tx(s, 'EXPRESS', 1.86, 0.98, 2.6, 0.22, { fontSize: 10, color: C.white, bold: true });
  tx(s, 'Nền tảng Delivery & Drive\nrealtime trên mobile', 0.75, 2.08, 7.5, 1.35, { fontSize: 35, color: C.white, bold: true, valign: 'top' });
  tx(s, 'Đồ án tốt nghiệp • Bảo vệ 10–15 phút', 0.78, 3.72, 5.8, 0.28, { fontSize: 15, color: 'B9C9D5' });
  line(s, 0.78, 4.35, 4.5, 4.35, C.mint, 2.2);
  tx(s, 'Một nền tảng, hai dịch vụ, một nguồn dữ liệu chuẩn.', 0.78, 4.6, 7.0, 0.34, { fontSize: 18, color: C.mintPale, bold: true });
  pill(s, 'DELIVERY', 0.78, 5.65, 1.55, C.mint, C.navy, { h: 0.38, fontSize: 10 });
  pill(s, 'DRIVE', 2.48, 5.65, 1.25, C.amber, C.navy, { h: 0.38, fontSize: 10 });
  pill(s, 'FLUTTER • LARAVEL • NODE.JS', 3.92, 5.65, 2.65, C.navy2, C.mintPale, { h: 0.38, fontSize: 9 });
  tx(s, '2026', 11.95, 6.72, 0.7, 0.25, { fontSize: 11, color: 'B9C9D5', align: 'right' });
  notes(s, 'Mở đầu trong 30–45 giây: giới thiệu FastRide Express là nền tảng gồm hai dịch vụ Delivery và Drive. Nhấn mạnh điểm xuyên suốt của đồ án: mobile tách vai trò nhưng dùng chung backend và cùng một nguồn dữ liệu chuẩn.');
}

// 2. Problem and objective
{
  const s = pptx.addSlide('BASE');
  addHeader(s, '01 • Bài toán', 'Từ nhu cầu di chuyển đến một hệ thống thống nhất', 'Tách trải nghiệm theo vai trò, nhưng giữ nghiệp vụ nhất quán ở backend.');
  card(s, 0.62, 2.0, 5.82, 3.5, C.white, C.line);
  iconBadge(s, 0.92, 2.34, 0.58, C.mintPale, '→', C.mintDark, 20);
  tx(s, 'Delivery', 1.66, 2.26, 2.5, 0.3, { fontSize: 21, bold: true, color: C.navy });
  tx(s, 'Giao hàng nội thành', 1.66, 2.64, 3.0, 0.24, { fontSize: 11, color: C.muted });
  tx(s, 'Báo giá → ghép tài xế → lấy hàng → giao / hoàn', 0.96, 3.22, 4.85, 0.56, { fontSize: 15, color: C.ink, bold: true });
  pill(s, 'PROOF OF DELIVERY', 0.96, 4.18, 1.85, C.mintPale, C.mintDark, { h: 0.31, fontSize: 8.5 });
  pill(s, 'COD / WALLET', 2.95, 4.18, 1.45, C.amberPale, '8B5A00', { h: 0.31, fontSize: 8.5 });
  tx(s, 'Một điểm lấy • một điểm giao • có nhánh hoàn hàng', 0.96, 4.83, 4.9, 0.25, { fontSize: 10.5, color: C.muted });

  card(s, 6.82, 2.0, 5.84, 3.5, C.navy, C.navy);
  iconBadge(s, 7.12, 2.34, 0.58, C.amberPale, '⌖', '8B5A00', 19);
  tx(s, 'Drive', 7.86, 2.26, 2.2, 0.3, { fontSize: 21, bold: true, color: C.white });
  tx(s, 'Chở khách theo chuyến', 7.86, 2.64, 3.2, 0.24, { fontSize: 11, color: 'B9C9D5' });
  tx(s, 'Báo giá → ghép tài xế → đón khách → hoàn tất', 7.16, 3.22, 4.95, 0.56, { fontSize: 15, color: C.white, bold: true });
  pill(s, 'ETA REALTIME', 7.16, 4.18, 1.42, C.mint, C.navy, { h: 0.31, fontSize: 8.5 });
  pill(s, 'SOS / CHAT', 8.75, 4.18, 1.25, C.coralPale, '8D3328', { h: 0.31, fontSize: 8.5 });
  tx(s, 'Một điểm đón • một điểm đến • không bỏ qua state', 7.16, 4.83, 4.9, 0.25, { fontSize: 10.5, color: 'B9C9D5' });

  rect(s, 0.62, 5.86, 12.04, 0.72, C.mintPale, true);
  tx(s, 'Mục tiêu thiết kế', 0.92, 6.05, 1.55, 0.2, { fontSize: 10, color: C.mintDark, bold: true });
  tx(s, 'Hai app riêng theo vai trò • một API nghiệp vụ • realtime có kiểm soát • tài chính có sổ cái', 2.45, 6.01, 9.78, 0.28, { fontSize: 14, color: C.navy, bold: true });
  addFooter(s, 2, 'Nguồn: docs/00-tong-quan.md');
  notes(s, 'Khoảng 50 giây. Nêu hai bài toán người dùng: giao hàng và chở khách. Cả hai có cùng các bước báo giá, matching, thanh toán và đánh giá, nhưng state machine và bằng chứng thực hiện khác nhau. Vì vậy hệ thống phải dùng chung nền tảng nhưng không trộn dữ liệu Delivery và Drive.');
}

// 3. Scope and actors
{
  const s = pptx.addSlide('BASE');
  addHeader(s, '02 • Phạm vi', 'Bốn nhóm tác nhân, một vòng đời dịch vụ', 'Mỗi vai trò có UI riêng; quyền và transition luôn do server quyết định.');
  const actors = [
    { x: 0.62, fill: C.bluePale, accent: C.blue, badge: 'KH', title: 'Khách hàng', body: 'Tạo yêu cầu\nTheo dõi • thanh toán\nHủy • đánh giá • hỗ trợ' },
    { x: 3.76, fill: C.mintPale, accent: C.mintDark, badge: 'TX', title: 'Tài xế', body: 'KYC • online\nNhận offer • thực hiện\nThu tiền • rút ví' },
    { x: 6.9, fill: C.amberPale, accent: '9A6400', badge: 'AD', title: 'Admin / điều phối', body: 'Duyệt hồ sơ\nGiám sát • can thiệp\nAudit mọi thao tác' },
    { x: 10.04, fill: C.coralPale, accent: 'A34537', badge: 'RT', title: 'Hệ thống nền', body: 'Matching • route / ETA\nOutbox • realtime\nPush / SMS fallback' },
  ];
  for (const a of actors) {
    card(s, a.x, 2.05, 2.66, 2.75, C.white, C.line);
    circle(s, a.x + 0.25, 2.32, 0.55, a.fill);
    tx(s, a.badge, a.x + 0.25, 2.34, 0.55, 0.48, { fontSize: 10, color: a.accent, bold: true, align: 'center' });
    tx(s, a.title, a.x + 0.25, 3.07, 2.15, 0.3, { fontSize: 15, bold: true, color: C.navy });
    tx(s, a.body, a.x + 0.25, 3.58, 2.15, 0.92, { fontSize: 11, color: C.muted, valign: 'top' });
  }
  tx(s, 'Ranh giới sở hữu dữ liệu', 0.62, 5.42, 3.1, 0.28, { fontSize: 14, color: C.navy, bold: true });
  const ownership = [
    ['Mobile', 'UI + local state + retry'],
    ['Laravel worker', 'DB + state machine + payment'],
    ['Realtime service', 'Socket room + event delivery'],
    ['Redis', 'Queue / outbox / presence / TTL'],
  ];
  ownership.forEach((item, i) => {
    const x = 0.62 + i * 3.02;
    rect(s, x, 5.92, 2.74, 0.58, i === 1 ? C.navy : C.white, true, { color: i === 1 ? C.navy : C.line, width: 0.7 });
    tx(s, item[0], x + 0.16, 6.02, 1.16, 0.18, { fontSize: 10, color: i === 1 ? C.mint : C.teal, bold: true });
    tx(s, item[1], x + 1.08, 6.0, 1.46, 0.2, { fontSize: 8.8, color: i === 1 ? C.white : C.muted, align: 'right' });
  });
  addFooter(s, 3, 'Nguồn: docs/00-tong-quan.md • docs/implementation/README.md');
  notes(s, 'Khoảng 45 giây. Đi qua bốn nhóm actor và nhấn mạnh ownership. Mobile không tự tính giá hay tự đổi state. Worker là nơi duy nhất ghi DB và quyết định nghiệp vụ; realtime chỉ vận chuyển event và presence.');
}

// 4. Product walkthrough
{
  const s = pptx.addSlide('BASE');
  addHeader(s, '03 • Sản phẩm', 'Một trải nghiệm liền mạch cho cả khách và tài xế', 'Ảnh chụp từ các màn hình thiết kế/triển khai trong repo.');
  // phone frames
  const phones = [
    { p: IMG.clientHome, x: 0.85, label: 'Khách hàng • Trang chủ', tag: 'Dịch vụ / địa chỉ / ưu đãi', accent: C.mint },
    { p: IMG.clientProfile, x: 3.12, label: 'Khách hàng • Ví & hồ sơ', tag: 'Ví lạnh / thanh toán / hỗ trợ', accent: C.blue },
    { p: IMG.driverHistory, x: 6.75, label: 'Tài xế • Lịch sử hoạt động', tag: 'Ca chạy / trạng thái / thu nhập', accent: C.amber },
    { p: IMG.driverWallet, x: 9.02, label: 'Tài xế • Ví thu nhập', tag: 'Settlement / rút tiền / ngân hàng', accent: C.coral },
  ];
  for (const ph of phones) {
    rect(s, ph.x - 0.08, 1.93, 2.02, 4.64, C.navy, true, { color: C.navy, width: 0.6 });
    image(s, ph.p, ph.x, 2.03, 1.86, 4.35);
    circle(s, ph.x + 0.77, 1.95, 0.32, C.navy);
    tx(s, ph.label, ph.x - 0.1, 6.63, 2.05, 0.2, { fontSize: 10.5, color: C.navy, bold: true, align: 'center' });
    tx(s, ph.tag, ph.x - 0.1, 6.84, 2.05, 0.16, { fontSize: 8.6, color: ph.accent, bold: true, align: 'center' });
  }
  notes(s, 'Khoảng 60 giây. Đây là slide trình diễn sản phẩm. Bên trái là customer journey: chọn dịch vụ, địa chỉ, voucher và ví. Bên phải là driver journey: xem ca chạy, ví thu nhập và lịch sử. Hai app có ngôn ngữ thị giác khác nhau nhưng đều lấy trạng thái authoritative từ worker.');
}

// 5. End-to-end flow
{
  const s = pptx.addSlide('BASE');
  addHeader(s, '04 • Luồng nghiệp vụ', 'Từ quote đến hoàn tất trong một vòng đời có kiểm soát', 'Một flow dùng chung các điểm kiểm soát, nhưng tách state Delivery và Drive.');
  const steps = [
    { n: '01', title: 'Quote', body: 'Route + giá\n+ voucher', fill: C.bluePale, accent: C.blue },
    { n: '02', title: 'Create', body: 'Tạo order /\nbooking', fill: C.mintPale, accent: C.mintDark },
    { n: '03', title: 'Match', body: 'Offer → accept\nassignment', fill: C.amberPale, accent: '9A6400' },
    { n: '04', title: 'Execute', body: 'GPS + evidence\nstate transition', fill: C.coralPale, accent: 'A34537' },
    { n: '05', title: 'Settle', body: 'Wallet / cash\nreceipt + rating', fill: C.lilacPale, accent: C.lilac },
  ];
  steps.forEach((st, i) => {
    const x = 0.74 + i * 2.48;
    circle(s, x, 2.06, 0.62, st.fill);
    tx(s, st.n, x, 2.17, 0.62, 0.28, { fontSize: 11, color: st.accent, bold: true, align: 'center' });
    if (i < steps.length - 1) line(s, x + 0.74, 2.37, x + 2.12, 2.37, C.line, 1.8, true);
    tx(s, st.title, x - 0.2, 2.9, 1.55, 0.28, { fontSize: 16, color: C.navy, bold: true, align: 'center' });
    tx(s, st.body, x - 0.28, 3.38, 1.72, 0.52, { fontSize: 11, color: C.muted, align: 'center', valign: 'top' });
  });
  card(s, 0.74, 4.65, 5.8, 1.28, C.navy, C.navy);
  tx(s, 'Delivery', 1.02, 4.88, 1.15, 0.22, { fontSize: 15, color: C.mint, bold: true });
  tx(s, 'SEARCHING → ASSIGNED → PICKED_UP → IN_DELIVERY → DELIVERED / RETURNED', 2.24, 4.82, 3.94, 0.36, { fontSize: 10.2, color: C.white, bold: true });
  tx(s, 'Bằng chứng: geofence • người nhận xác nhận • ảnh / checksum', 1.02, 5.35, 5.1, 0.2, { fontSize: 9.4, color: 'B9C9D5' });
  card(s, 6.78, 4.65, 5.8, 1.28, C.white, C.line);
  tx(s, 'Drive', 7.06, 4.88, 1.15, 0.22, { fontSize: 15, color: C.teal, bold: true });
  tx(s, 'SEARCHING → ASSIGNED → ARRIVING → ARRIVED → IN_TRIP → COMPLETED', 8.28, 4.82, 3.94, 0.36, { fontSize: 10.2, color: C.navy, bold: true });
  tx(s, 'Bằng chứng: GPS snapshot • ETA • xác nhận đón / kết thúc', 7.06, 5.35, 5.1, 0.2, { fontSize: 9.4, color: C.muted });
  rect(s, 0.74, 6.2, 11.84, 0.42, C.mintPale, true);
  tx(s, 'Nguyên tắc: server quyết định trạng thái; command lặp lại phải idempotent.', 0.98, 6.31, 11.35, 0.18, { fontSize: 11, color: C.mintDark, bold: true, align: 'center' });
  addFooter(s, 5, 'Nguồn: docs/flows/03–10 • docs/00-tong-quan.md');
  notes(s, 'Khoảng 60 giây. Trình bày năm bước chung. Sau đó phân biệt hai state machine: Delivery có pickup, proof và nhánh return; Drive có arriving, arrived và in-trip. Mọi command kiểm tra current_status trong transaction, ghi status history và dùng idempotency key.');
}

// 6. Architecture
{
  const s = pptx.addSlide();
  s.background = { color: C.navy };
  tx(s, '05 • KIẾN TRÚC', 0.62, 0.42, 3.0, 0.22, { fontSize: 9, color: C.mint, bold: true });
  tx(s, 'Tách nghiệp vụ, realtime và dữ liệu chuẩn', 0.62, 0.72, 10.9, 0.54, { fontSize: 28, color: C.white, bold: true });
  tx(s, 'Laravel giữ quyền quyết định; Node.js vận chuyển event; Redis chỉ giữ trạng thái ngắn hạn.', 0.64, 1.35, 11.7, 0.3, { fontSize: 12, color: 'B9C9D5' });
  // left clients
  card(s, 0.78, 2.15, 2.12, 1.13, C.navy2, '29445A');
  tx(s, 'CUSTOMER APP', 0.98, 2.42, 1.72, 0.2, { fontSize: 12, color: C.mint, bold: true, align: 'center' });
  tx(s, 'Flutter • HTTPS + Socket.IO', 0.98, 2.72, 1.72, 0.2, { fontSize: 9, color: 'B9C9D5', align: 'center' });
  card(s, 0.78, 3.75, 2.12, 1.13, C.navy2, '29445A');
  tx(s, 'DRIVER APP', 0.98, 4.02, 1.72, 0.2, { fontSize: 12, color: C.amber, bold: true, align: 'center' });
  tx(s, 'Flutter • GPS heartbeat', 0.98, 4.32, 1.72, 0.2, { fontSize: 9, color: 'B9C9D5', align: 'center' });
  // core
  card(s, 3.55, 2.55, 2.7, 2.0, C.mint, C.mint);
  tx(s, 'LARAVEL WORKER', 3.82, 2.88, 2.16, 0.25, { fontSize: 14, color: C.navy, bold: true, align: 'center' });
  tx(s, 'API • auth • state machine\nmatching • payment • audit\ntransactional outbox', 3.84, 3.35, 2.12, 0.76, { fontSize: 11, color: C.navy, bold: true, align: 'center', valign: 'top' });
  card(s, 7.0, 2.55, 2.32, 2.0, C.teal, C.teal);
  tx(s, 'NODE.JS REALTIME', 7.22, 2.88, 1.88, 0.25, { fontSize: 13, color: C.white, bold: true, align: 'center' });
  tx(s, 'Socket.IO rooms\nRedis consumer\npush dispatch', 7.28, 3.35, 1.76, 0.72, { fontSize: 11, color: C.white, bold: true, align: 'center', valign: 'top' });
  // storage
  card(s, 10.1, 2.22, 2.15, 1.22, C.white, C.white);
  tx(s, 'POSTGRESQL', 10.36, 2.55, 1.64, 0.22, { fontSize: 12, color: C.navy, bold: true, align: 'center' });
  tx(s, 'Nguồn dữ liệu chuẩn', 10.36, 2.88, 1.64, 0.18, { fontSize: 9.5, color: C.muted, align: 'center' });
  card(s, 10.1, 4.0, 2.15, 1.22, C.navy2, '29445A');
  tx(s, 'REDIS', 10.36, 4.33, 1.64, 0.22, { fontSize: 12, color: C.mint, bold: true, align: 'center' });
  tx(s, 'Queue • outbox • TTL', 10.36, 4.66, 1.64, 0.18, { fontSize: 9.5, color: 'B9C9D5', align: 'center' });
  // arrows
  line(s, 2.9, 2.7, 3.55, 3.08, C.mint, 1.6, true);
  line(s, 2.9, 4.3, 3.55, 4.0, C.amber, 1.6, true);
  line(s, 6.25, 3.22, 7.0, 3.22, C.white, 1.6, true);
  line(s, 6.25, 3.8, 7.0, 3.8, C.mint, 1.6, true);
  line(s, 6.25, 4.0, 10.1, 4.48, '6A8CA2', 1.2, true, 'dash');
  line(s, 9.32, 3.22, 10.1, 2.83, C.white, 1.3, true);
  rect(s, 3.55, 5.35, 5.77, 0.62, C.navy2, true, { color: '29445A', width: 0.7 });
  tx(s, 'Goong route / ETA      •      Firebase push      •      SePay top-up', 3.7, 5.55, 5.47, 0.2, { fontSize: 10.5, color: 'B9C9D5', bold: true, align: 'center' });
  rect(s, 0.78, 6.25, 11.47, 0.48, C.mintPale, true);
  tx(s, 'Socket.IO không là nguồn dữ liệu chuẩn. Sau reconnect, app luôn nạp snapshot từ worker.', 1.02, 6.39, 10.98, 0.18, { fontSize: 11.5, color: C.mintDark, bold: true, align: 'center' });
  notes(s, 'Khoảng 70 giây. Đây là slide kiến trúc chính. Đi từ hai mobile vào Laravel worker. Worker ghi PostgreSQL trong transaction, sau commit mới đẩy outbox vào Redis. Node.js nhận event, phát đúng room Socket.IO và đẩy notification. Redis giữ queue, presence và TTL; không giữ trạng thái thanh toán hay state cuối.');
}

// 7. Matching and realtime
{
  const s = pptx.addSlide('BASE');
  addHeader(s, '06 • Matching & realtime', 'Offer nhanh, winner duy nhất, reconnect không mất trạng thái', 'Thiết kế ưu tiên tính đúng trước khi tối ưu tải.');
  const cols = [0.82, 3.0, 5.18, 7.36, 9.54];
  const labels = ['Driver', 'Presence', 'Worker', 'Redis / Outbox', 'Customer'];
  labels.forEach((l, i) => {
    rect(s, cols[i], 2.0, 1.72, 0.46, i === 2 ? C.mint : C.navy, true);
    tx(s, l, cols[i], 2.13, 1.72, 0.18, { fontSize: 10.5, color: i === 2 ? C.navy : C.white, bold: true, align: 'center' });
  });
  const events = [
    { y: 2.88, from: 0, to: 2, text: 'online + GPS heartbeat' },
    { y: 3.42, from: 2, to: 1, text: 'filter approved / TTL / GEO' },
    { y: 3.96, from: 2, to: 0, text: 'offer batch + expiry' },
    { y: 4.5, from: 0, to: 2, text: 'accept (Idempotency-Key)' },
    { y: 5.04, from: 2, to: 3, text: 'commit assignment + outbox' },
    { y: 5.58, from: 3, to: 4, text: 'event → private room' },
  ];
  events.forEach((e, idx) => {
    const x1 = cols[e.from] + 0.86;
    const x2 = cols[e.to] + 0.86;
    line(s, x1, e.y, x2, e.y, idx === 4 ? C.mintDark : C.teal, 1.35, true);
    tx(s, e.text, Math.min(x1, x2) + 0.1, e.y - 0.25, Math.abs(x2 - x1) - 0.2, 0.18, { fontSize: 8.6, color: C.muted, align: 'center' });
  });
  card(s, 0.82, 6.25, 3.62, 0.52, C.mintPale, C.mintPale);
  tx(s, 'Partial unique index: 1 assignment active', 1.0, 6.4, 3.25, 0.18, { fontSize: 9.5, color: C.mintDark, bold: true, align: 'center' });
  card(s, 4.66, 6.25, 3.62, 0.52, C.amberPale, C.amberPale);
  tx(s, 'Event duplicate / out-of-order có guard', 4.84, 6.4, 3.25, 0.18, { fontSize: 9.5, color: '8B5A00', bold: true, align: 'center' });
  card(s, 8.5, 6.25, 3.62, 0.52, C.bluePale, C.bluePale);
  tx(s, 'Reconnect → snapshot authoritative', 8.68, 6.4, 3.25, 0.18, { fontSize: 9.5, color: C.blue, bold: true, align: 'center' });
  addFooter(s, 7, 'Nguồn: docs/implementation/README.md • service/src/realtime');
  notes(s, 'Khoảng 60 giây. Mô tả một offer: tài xế gửi presence và GPS, worker lọc ứng viên, tạo offer batch. Khi accept, worker khóa request và driver trong transaction; chỉ một assignment active. Outbox publish sau commit. Nếu socket mất, customer và driver nạp snapshot từ API; event chỉ là tín hiệu cập nhật.');
}

// 8. State machines
{
  const s = pptx.addSlide('BASE');
  addHeader(s, '07 • State machine', 'Delivery và Drive: cùng khung, khác nghiệp vụ', 'Tách state giúp tránh cập nhật nhầm trạng thái và xử lý ngoại lệ rõ ràng.');
  tx(s, 'DELIVERY', 0.82, 2.0, 1.5, 0.22, { fontSize: 11, color: C.mintDark, bold: true });
  tx(s, 'DRIVE', 0.82, 4.37, 1.5, 0.22, { fontSize: 11, color: C.teal, bold: true });
  const d = ['SEARCHING', 'ASSIGNED', 'AT_PICKUP', 'PICKED_UP', 'IN_DELIVERY', 'DELIVERED'];
  const r = ['SEARCHING', 'ASSIGNED', 'ARRIVING', 'ARRIVED', 'IN_TRIP', 'COMPLETED'];
  const drawStates = (states, y, fill, textColor) => {
    states.forEach((st, i) => {
      const x = 1.72 + i * 1.83;
      rect(s, x, y, 1.46, 0.56, i === states.length - 1 ? fill : C.white, true, { color: i === states.length - 1 ? fill : C.line, width: 0.8 });
      tx(s, st, x, y + 0.18, 1.46, 0.17, { fontSize: 8.2, color: i === states.length - 1 ? textColor : C.navy, bold: true, align: 'center' });
      if (i < states.length - 1) line(s, x + 1.49, y + 0.28, x + 1.78, y + 0.28, C.line, 1.25, true);
    });
  };
  drawStates(d, 2.0, C.mint, C.navy);
  drawStates(r, 4.37, C.teal, C.white);
  rect(s, 1.72, 2.93, 10.54, 0.76, C.mintPale, true);
  tx(s, 'Ngoại lệ Delivery', 1.98, 3.13, 1.55, 0.2, { fontSize: 10, color: C.mintDark, bold: true });
  tx(s, 'Giao thất bại sau pickup → RETURN_REQUESTED → RETURNING → RETURNED', 3.62, 3.11, 6.98, 0.24, { fontSize: 11, color: C.navy, bold: true });
  tx(s, 'Không tạo order hoàn mới; vẫn giữ cùng DeliveryOrder.', 3.62, 3.4, 6.98, 0.18, { fontSize: 9.5, color: C.muted });
  rect(s, 1.72, 5.3, 10.54, 0.76, C.bluePale, true);
  tx(s, 'Nguyên tắc Drive', 1.98, 5.5, 1.55, 0.2, { fontSize: 10, color: C.blue, bold: true });
  tx(s, 'Không hủy thông thường khi IN_TRIP; sự cố phải lưu điểm kết thúc thực tế.', 3.62, 5.48, 7.0, 0.24, { fontSize: 11, color: C.navy, bold: true });
  tx(s, 'Mọi transition ghi actor, reason, timestamp và correlation id.', 3.62, 5.77, 6.98, 0.18, { fontSize: 9.5, color: C.muted });
  addFooter(s, 8, 'Nguồn: docs/00-tong-quan.md • docs/flows/05, 08, 10');
  notes(s, 'Khoảng 55 giây. So sánh state machine. Delivery có pickup và nhánh return trên cùng order. Drive có arriving/arrived/in-trip; không hủy thông thường giữa chuyến. Đây là phần thể hiện rõ nhất việc tách nghiệp vụ dù dùng chung hạ tầng.');
}

// 9. Finance
{
  const s = pptx.addSlide('BASE');
  addHeader(s, '08 • Tài chính', 'Ví, tiền mặt và voucher đều đi qua sổ cái có đối soát', 'Settlement độc lập với trạng thái dịch vụ để không mất bằng chứng khi ghi sổ lỗi.');
  card(s, 0.72, 1.98, 5.1, 3.96, C.navy, C.navy);
  tx(s, 'Công thức quyết toán', 1.05, 2.35, 3.0, 0.25, { fontSize: 16, color: C.mint, bold: true });
  tx(s, 'driver_net_earning', 1.05, 2.98, 2.45, 0.28, { fontSize: 19, color: C.white, bold: true });
  tx(s, '= cash_collected\n  + wallet_payment_amount\n  + voucher_payment_amount\n  − platform_fee_debited', 1.05, 3.52, 3.96, 1.12, { fontSize: 14, color: 'E8F0F4', bold: true, valign: 'top' });
  pill(s, 'driver rate snapshot: 88%', 1.05, 5.12, 2.02, C.amber, C.navy, { h: 0.34, fontSize: 9 });
  tx(s, 'Ví tài xế chỉ ghi sổ sau khi dịch vụ hoàn tất.', 1.05, 5.56, 4.12, 0.2, { fontSize: 10.5, color: 'B9C9D5' });

  card(s, 6.2, 1.98, 6.42, 3.96, C.white, C.line);
  tx(s, 'Ví dụ: gross fare = 100.000đ', 6.55, 2.35, 4.1, 0.25, { fontSize: 16, color: C.navy, bold: true });
  const rows = [
    ['Khách trả', '80.000đ', C.bluePale, C.blue],
    ['Voucher tài trợ', '20.000đ', C.amberPale, '8B5A00'],
    ['Thu nhập gộp tài xế', '88.000đ', C.mintPale, C.mintDark],
    ['Phí nền tảng', '12.000đ', C.coralPale, 'A34537'],
  ];
  rows.forEach((row, i) => {
    const y = 2.92 + i * 0.55;
    rect(s, 6.55, y, 5.72, 0.42, row[2], true);
    tx(s, row[0], 6.78, y + 0.11, 3.2, 0.16, { fontSize: 10.5, color: C.navy, bold: i === 2 });
    tx(s, row[1], 11.2, y + 0.11, 0.82, 0.16, { fontSize: 10.5, color: row[3], bold: true, align: 'right' });
  });
  rect(s, 6.55, 5.32, 5.72, 0.4, C.navy, true);
  tx(s, 'voucher không tự động cộng vào số dư ví', 6.72, 5.43, 5.35, 0.16, { fontSize: 9.8, color: C.white, bold: true, align: 'center' });
  rect(s, 0.72, 6.24, 11.9, 0.5, C.mintPale, true);
  tx(s, 'Idempotency + ledger entries + debit = credit + audit trail', 0.96, 6.39, 11.42, 0.18, { fontSize: 11.2, color: C.mintDark, bold: true, align: 'center' });
  addFooter(s, 9, 'Nguồn: docs/flows/09-thanh-toan-va-hoan-tien.md');
  notes(s, 'Khoảng 60 giây. Giải thích vì sao payment và service status độc lập. Ví dụ 100.000 đồng: voucher giảm phần khách trả nhưng không làm giảm gross earning của tài xế; phí nền tảng ghi sau hoàn tất. Mọi giao dịch có idempotency key và ledger cân bằng.');
}

// 10. Security and reliability
{
  const s = pptx.addSlide('BASE');
  s.background = { color: C.navy };
  tx(s, '09 • AN TOÀN & ĐỘ TIN CẬY', 0.62, 0.42, 4.8, 0.22, { fontSize: 9, color: C.mint, bold: true });
  tx(s, 'Tin cậy được thiết kế vào từng transition', 0.62, 0.72, 10.9, 0.54, { fontSize: 28, color: C.white, bold: true });
  tx(s, 'Tập trung vào đúng người, đúng trạng thái, đúng bằng chứng.', 0.64, 1.35, 11.7, 0.3, { fontSize: 12, color: 'B9C9D5' });
  const controls = [
    ['AUTH', 'OTP chỉ xác minh số điện thoại\nSanctum token + secure storage', C.mint, C.mintPale],
    ['ACCESS', 'Booking room và file private\nđược authorize qua worker', C.blue, C.bluePale],
    ['DATA', 'GPS chỉ lưu snapshot cuối\nPII / evidence không public', C.amber, C.amberPale],
    ['RECOVERY', 'Idempotency + outbox\nreconnect lấy snapshot chuẩn', C.coral, C.coralPale],
  ];
  controls.forEach((c, i) => {
    const x = 0.78 + (i % 2) * 6.1;
    const y = 2.08 + Math.floor(i / 2) * 1.65;
    card(s, x, y, 5.42, 1.24, C.navy2, '29445A');
    circle(s, x + 0.28, y + 0.32, 0.58, c[3]);
    tx(s, c[0], x + 0.28, y + 0.48, 0.58, 0.15, { fontSize: 8.5, color: c[2], bold: true, align: 'center' });
    tx(s, c[1], x + 1.08, y + 0.29, 3.96, 0.58, { fontSize: 12, color: C.white, bold: true, valign: 'top' });
    line(s, x + 1.08, y + 0.96, x + 4.88, y + 0.96, c[2], 1.5);
  });
  rect(s, 0.78, 5.65, 11.54, 0.76, C.mint, true);
  tx(s, 'Server quyết định trạng thái • client gửi command • mọi transition có history', 1.02, 5.9, 11.06, 0.24, { fontSize: 14, color: C.navy, bold: true, align: 'center' });
  tx(s, 'Đây là đường biên an toàn quan trọng nhất của hệ thống.', 0.82, 6.58, 11.3, 0.18, { fontSize: 10.5, color: 'B9C9D5', align: 'center', italic: true });
  notes(s, 'Khoảng 50 giây. Nêu bốn lớp kiểm soát: auth, authorization, bảo vệ dữ liệu nhạy cảm và recovery. Có thể nhấn mạnh location chỉ là snapshot cuối, evidence private, room realtime kiểm tra quyền và mọi command retry giữ nguyên idempotency key.');
}

// 11. Implementation and verification
{
  const s = pptx.addSlide('BASE');
  addHeader(s, '10 • Kết quả', 'MVP đã đi qua end-to-end; còn lại là hardening', 'Các phase nghiệp vụ và mobile đã hoàn tất theo implementation plan.');
  const phases = [
    ['0–4', 'Foundation → request', C.blue, 'COMPLETED'],
    ['5–6', 'Matching → execution', C.mintDark, 'COMPLETED'],
    ['7–8', 'Finance → support', '9A6400', 'COMPLETED'],
    ['9–10', 'Customer + driver app', C.teal, 'COMPLETED'],
    ['11', 'Hardening / demo seed', C.coral, 'PENDING'],
  ];
  phases.forEach((p, i) => {
    const x = 0.72 + i * 2.48;
    rect(s, x, 2.0, 2.18, 1.38, i === 4 ? C.coralPale : C.mintPale, true);
    tx(s, p[0], x + 0.18, 2.22, 0.6, 0.28, { fontSize: 20, color: p[2], bold: true });
    tx(s, p[1], x + 0.18, 2.7, 1.78, 0.32, { fontSize: 10.5, color: C.navy, bold: true, valign: 'top' });
    tx(s, p[3], x + 0.18, 3.1, 1.74, 0.16, { fontSize: 8.5, color: p[2], bold: true });
  });
  tx(s, 'Dấu vết kiểm chứng trong repo', 0.72, 4.08, 3.8, 0.28, { fontSize: 16, color: C.navy, bold: true });
  const facts = [
    ['50', 'API controllers'],
    ['52', 'domain models'],
    ['21', 'database migrations'],
    ['35', 'PHP test files'],
    ['13', 'service + mobile test files'],
  ];
  facts.forEach((f, i) => {
    const x = 0.72 + i * 2.48;
    card(s, x, 4.62, 2.18, 1.14, C.white, C.line);
    tx(s, f[0], x + 0.16, 4.82, 0.72, 0.36, { fontSize: 24, color: i === 0 ? C.teal : C.navy, bold: true });
    tx(s, f[1], x + 0.18, 5.3, 1.78, 0.2, { fontSize: 9.4, color: C.muted, bold: true });
  });
  rect(s, 0.72, 6.18, 11.9, 0.48, C.navy, true);
  tx(s, 'Ưu tiên nghiệm thu: chạy được flow thật, state đúng, reconnect và đối soát không trùng.', 0.94, 6.31, 11.46, 0.18, { fontSize: 11, color: C.white, bold: true, align: 'center' });
  addFooter(s, 11, 'Nguồn: docs/implementation/README.md • thống kê file trong repo');
  notes(s, 'Khoảng 50 giây. Dẫn qua trạng thái phase: 0–10 hoàn tất, phase 11 còn hardening và demo seed. Các con số là dấu vết trong repo, không phải benchmark tải. Kết luận: MVP đã có đường đi end-to-end, phần tiếp theo là tăng độ bền và chuẩn hóa demo/deploy.');
}

// 12. Demo and close
{
  const s = pptx.addSlide();
  s.background = { color: C.navy };
  tx(s, '11 • KẾT LUẬN', 0.62, 0.42, 3.1, 0.22, { fontSize: 9, color: C.mint, bold: true });
  tx(s, 'Kịch bản demo 3 phút', 0.62, 0.72, 8.8, 0.54, { fontSize: 29, color: C.white, bold: true });
  tx(s, 'Một câu chuyện ngắn để chứng minh hệ thống chạy xuyên suốt.', 0.64, 1.35, 10.8, 0.3, { fontSize: 12, color: 'B9C9D5' });
  const demo = [
    ['1', 'Customer', 'Đăng nhập → chọn Delivery → nhận quote → tạo đơn'],
    ['2', 'Driver', 'Online → nhận offer → accept → cập nhật vị trí'],
    ['3', 'Realtime', 'Customer thấy trạng thái / ETA qua booking room'],
    ['4', 'Settlement', 'Hoàn tất → receipt → ledger → rating'],
  ];
  demo.forEach((d, i) => {
    const y = 2.12 + i * 0.88;
    circle(s, 0.84, y + 0.04, 0.48, i === 3 ? C.amber : C.mint);
    tx(s, d[0], 0.84, y + 0.14, 0.48, 0.17, { fontSize: 11, color: C.navy, bold: true, align: 'center' });
    tx(s, d[1], 1.62, y + 0.03, 1.65, 0.22, { fontSize: 14, color: i === 3 ? C.amber : C.mint, bold: true });
    tx(s, d[2], 3.28, y + 0.03, 7.7, 0.22, { fontSize: 13, color: C.white, bold: true });
    line(s, 1.08, y + 0.6, 10.9, y + 0.6, '29445A', 0.8);
  });
  rect(s, 0.78, 6.02, 11.5, 0.6, C.mint, true);
  tx(s, 'FastRide Express = hai app tách vai trò + một backend giữ sự nhất quán.', 1.02, 6.2, 11.02, 0.22, { fontSize: 14, color: C.navy, bold: true, align: 'center' });
  tx(s, 'Cảm ơn hội đồng. Sẵn sàng demo và trả lời câu hỏi.', 0.8, 6.87, 11.45, 0.18, { fontSize: 10.5, color: 'B9C9D5', align: 'center' });
  notes(s, 'Kết thúc trong 30–45 giây. Nếu được demo trực tiếp, đi theo đúng bốn bước: customer tạo Delivery, driver nhận offer, customer thấy realtime, hoàn tất và xem settlement. Chốt lại thông điệp: hai app tách vai trò, nhưng backend giữ sự nhất quán và audit được.');
}

await pptx.writeFile({ fileName: ASSET('docs', 'defense-slides.pptx'), compression: true });
console.log('Generated docs/defense-slides.pptx');
