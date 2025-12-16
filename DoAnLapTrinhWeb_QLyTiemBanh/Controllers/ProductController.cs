
using DoAnLapTrinhWeb_QLyTiemBanh.Repositories;
using Microsoft.AspNetCore.Mvc;
namespace DoAnLapTrinhWeb_QLyTiemBanh.Controllers
{

    public class ProductController : Controller
    {
        private readonly IProductRepository _productRepository;
        private readonly ICategoryRepository _categoryRepository;
        public ProductController(IProductRepository productRepository, ICategoryRepository categoryRepository)
        {
            _productRepository = productRepository;
            _categoryRepository = categoryRepository;
        }
        // Hiển thị danh sách sản phẩm 
        public async Task<IActionResult> Index()
        {
            var products = await _productRepository.GetAllAsync();
            return View(products);
        }
        // Hiển thị thông tin chi tiết sản phẩm 
        public async Task<IActionResult> Details(int id)
        {
            var product = await _productRepository.GetByIdAsync(id);
            if (product == null)
            {
                return NotFound();
            }
            return View(product);
        }
        public async Task<IActionResult> ComboGift()
        {
            var allProducts = await _productRepository.GetAllAsync();

            var comboProducts = allProducts.Where(p => p.Category?.TenLoai == "Combo/Gift").ToList();


            return View(comboProducts);
        }

    }
}
