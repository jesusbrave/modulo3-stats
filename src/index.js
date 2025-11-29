const AWS = require('aws-sdk');
const ddb = new AWS.DynamoDB.DocumentClient();

// Helper: format YYYY-MM-DD
function todayISO() {
  const d = new Date();
  return d.toISOString().slice(0, 10);
}

exports.handler = async (event) => {
  try {
    const code = event.pathParameters && event.pathParameters.codigo;
    if (!code) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'codigo path param required' })
      };
    }

    const qs = event.queryStringParameters || {};
    const start = qs.start_date || qs.start || null;
    const end = qs.end_date || qs.end || null;

    const table = process.env.DDB_TABLE_STATS;
    if (!table) {
      return { statusCode: 500, body: JSON.stringify({ error: 'DDB_TABLE_STATS not configured' }) };
    }

    let params = {
      TableName: table,
      KeyConditionExpression: '#code = :c',
      ExpressionAttributeNames: { '#code': 'code' },
      ExpressionAttributeValues: { ':c': code }
    };

    if (start && end) {
      params.KeyConditionExpression += ' AND #date BETWEEN :start AND :end';
      params.ExpressionAttributeNames['#date'] = 'date';
      params.ExpressionAttributeValues[':start'] = start;
      params.ExpressionAttributeValues[':end'] = end;
    } else if (start) {
      params.KeyConditionExpression += ' AND #date >= :start';
      params.ExpressionAttributeNames['#date'] = 'date';
      params.ExpressionAttributeValues[':start'] = start;
    } else if (end) {
      params.KeyConditionExpression += ' AND #date <= :end';
      params.ExpressionAttributeNames['#date'] = 'date';
      params.ExpressionAttributeValues[':end'] = end;
    } else {
      const e = new Date();
      const s = new Date();
      s.setDate(e.getDate() - 29);
      const sISO = s.toISOString().slice(0, 10);
      const eISO = e.toISOString().slice(0, 10);
      params.KeyConditionExpression += ' AND #date BETWEEN :start AND :end';
      params.ExpressionAttributeNames['#date'] = 'date';
      params.ExpressionAttributeValues[':start'] = sISO;
      params.ExpressionAttributeValues[':end'] = eISO;
    }

    const items = [];
    let data;
    do {
      data = await ddb.query(params).promise();
      if (data.Items) items.push(...data.Items);
      params.ExclusiveStartKey = data.LastEvaluatedKey;
    } while (data.LastEvaluatedKey);

    items.sort((a, b) => a.date.localeCompare(b.date));
    const response = items.map(it => ({ date: it.date, count: it.count }));

    return {
      statusCode: 200,
      body: JSON.stringify({ code, stats: response }),
      headers: { 'Content-Type': 'application/json' }
    };

  } catch (err) {
    console.error(err)
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'internal_error', detail: err.message })
    };
  }
};