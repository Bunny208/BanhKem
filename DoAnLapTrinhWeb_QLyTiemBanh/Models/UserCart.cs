using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc.ModelBinding.Validation;
using System.ComponentModel.DataAnnotations.Schema;

namespace DoAnLapTrinhWeb_QLyTiemBanh.Models
{
    public class UserCart
    {
        [Key]
        public int Id { get; set; }

        public string UserId { get; set; }
        [ForeignKey("UserId")]
        [ValidateNever]
        public ApplicationUser ApplicationUser { get; set; }
       
        public ICollection<CartItem>? CartItems { get; set; } = new List<CartItem>();
    }
}
