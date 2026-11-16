// n8n Code node ("Run Once for All Items"), placed AFTER the AI summary node.
// It reads the numbers from the Postgres node (named "Sales Data")
// and the AI text from the previous node, then builds the email.

const d = $('Sales Data').first().json;
const aiSummary = ($input.first().json.text || '').trim();

const taka = (n) => '৳' + Number(n || 0).toLocaleString('en-IN', { maximumFractionDigits: 0 });
const change = d.revenue_change_pct === null ? null : Number(d.revenue_change_pct);
const arrow = change === null ? '–' : change >= 0 ? `▲ ${change}%` : `▼ ${Math.abs(change)}%`;
const arrowColor = change === null ? '#666' : change >= 0 ? '#1a7f37' : '#c62828';

const rows = (list, cells) =>
  (list || []).map((r) => `<tr>${cells(r).map((c) => `<td style="padding:6px 10px;border-bottom:1px solid #eee">${c}</td>`).join('')}</tr>`).join('');

const table = (headers, body) => `
  <table style="border-collapse:collapse;width:100%;font-size:14px;margin:8px 0 20px">
    <tr>${headers.map((h) => `<th style="text-align:left;padding:6px 10px;background:#f4f6f8">${h}</th>`).join('')}</tr>
    ${body}
  </table>`;

const html = `
<div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;color:#222">
  <h2 style="margin-bottom:4px">Daily Sales Report</h2>
  <div style="color:#666;margin-bottom:16px">${d.report_date}</div>

  <div style="background:#f4f6f8;border-radius:8px;padding:14px 16px;margin-bottom:20px">
    <b>Summary</b><br>${aiSummary.replace(/\n/g, '<br>')}
  </div>

  <table style="width:100%;margin-bottom:20px;font-size:14px">
    <tr>
      <td><div style="color:#666">Revenue</div><div style="font-size:22px"><b>${taka(d.revenue_yesterday)}</b></div>
          <div style="color:${arrowColor}">${arrow} vs day before</div></td>
      <td><div style="color:#666">Orders</div><div style="font-size:22px"><b>${d.orders_yesterday}</b></div>
          <div style="color:#666">day before: ${d.orders_day_before}</div></td>
      <td><div style="color:#666">Avg. order</div><div style="font-size:22px"><b>${taka(d.avg_order_value)}</b></div>
          <div style="color:#666">cancelled: ${d.cancelled_yesterday}</div></td>
    </tr>
  </table>

  <h3>Top products</h3>
  ${table(['Product', 'Units', 'Revenue'], rows(d.top_products, (r) => [r.product, r.units, taka(r.revenue)]))}

  <h3>By category</h3>
  ${table(['Category', 'Revenue'], rows(d.by_category, (r) => [r.category, taka(r.revenue)]))}

  <h3>Orders by city</h3>
  ${table(['City', 'Orders'], rows(d.by_city, (r) => [r.city, r.orders]))}

  <div style="color:#999;font-size:12px">Sent automatically by n8n.</div>
</div>`;

return [{
  json: {
    subject: `Sales report ${d.report_date}: ${taka(d.revenue_yesterday)} (${arrow})`,
    html,
  },
}];
