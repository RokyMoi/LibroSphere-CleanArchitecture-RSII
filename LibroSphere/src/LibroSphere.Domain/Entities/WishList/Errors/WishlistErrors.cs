using LibroSphere.Domain.Abstraction;

namespace LibroSphere.Domain.Entities.WishList.Errors
{
    public static class WishlistErrors
    {
        public static readonly Error NotFound = new("Wishlist.NotFound", "Wishlist for specified user was not found");
        public static readonly Error BookAlreadyInWishlist = new("Wishlist.BookAlreadyExists", "Book already exists in wishlist");
        public static readonly Error BookNotInWishlist = new("Wishlist.BookNotFound", "Book does not exist in wishlist");
    }
}
