# جمجم | Jumjum V5

لعبة أسئلة ومعرفة عربية بنمط مغامرة، مع تجارب عمرية للأطفال ونظام منافسة مستقل.

## مرجع المنتج
- [دستور جمجم V5](docs/JUMJUM_V5_CONSTITUTION.md)

## التقنية المعتمدة
- HTML5 / CSS3 / Vanilla JavaScript
- Cloudflare Pages + Pages Functions
- Cloudflare D1 لبيانات اللعبة والإعدادات والمراحل
- Turso لبيانات اللاعبين والعائلات والتقدم
- Firebase Authentication لتسجيل الدخول وإثبات الهوية
- Servimg وFAMO-PIC لاستضافة الصور مؤقتًا

## قاعدة الأمان
لا يتصل المتصفح مباشرة بقاعدة D1 أو Turso. تمر عمليات البيانات عبر Pages Functions بعد التحقق من هوية Firebase وتطبيق صلاحيات الملكية. لا توضع مفاتيح أو أسرار خدمة في الواجهة أو Git.

راجع [خطة التخزين والبنية](docs/STORAGE_ARCHITECTURE.md) و[حالة قواعد البيانات](docs/DATABASE_SETUP_STATUS.md).
