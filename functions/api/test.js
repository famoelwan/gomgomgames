export async function onRequest(context) {
  try {
    // استعلام بسيط جدًا على جدول النظام
    const ps = context.env.DB.prepare("SELECT 1 as test");
    const result = await ps.first();

    return new Response(JSON.stringify({
      status: "success",
      message: "D1 binding is working!",
      result: result,
      db_id: "8f6841a6-9548-4302-89db-47599721c192"
    }), {
      headers: { "Content-Type": "application/json" }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      status: "error",
      message: error.message
    }), {
      status: 500,
      headers: { "Content-Type": "application/json" }
    });
  }
} 
